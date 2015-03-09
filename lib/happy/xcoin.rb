require 'phantomjs/poltergeist'

module Happy
  module XCoin
    module Information
      attr_accessor :xcoin_user, :xcoin_password, :xcoin_password2

      def self.extended(mod)
        mod.xcoin_user = ENV['XCOIN_USER']
        mod.xcoin_password = ENV['XCOIN_PASSWORD']
        mod.xcoin_password2 = ENV['XCOIN_PASSWORD2']
      end

      def xcoin_not_found(*args)
        find(*args)
        return false
      rescue Capybara::ElementNotFound
        return true
      rescue
        return false
      end

      def xcoin_ensure_login
        Happy.logger.debug { 'xcoin_ensure_login' }
        visit 'https://www.xcoin.co.kr/u1/US101'
        if xcoin_not_found(:css, '.gnb_s1') && find(:css, '.gnb')
          Happy.logger.debug { 'already logged in' }
          return
        end
        Happy.logger.debug { 'Fill username and password' }
        fill_in 'j_username', with: xcoin_user
        fill_in 'j_password', with: xcoin_password
        Happy.logger.debug { 'Submit' }
        find(:xpath, '//p[@class="btn_org"]').click
        Happy.logger.debug { 'xcoin_ensure_login finished' }
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        retry
      end
    end

    module Market
      def self.extended(mod)
        [
          [Happy::Currency::KRW_X, Happy::Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_market[[base, counter]] = mod.method(:market_xcoin)
        end
      end

      Capybara.current_driver = :poltergeist
      include Capybara::DSL

      def market_xcoin(_base, _counter)
        # TODO: ensure base and counter
        visit 'http://www.xcoin.co.kr'
        Nokogiri.HTML(page.body).xpath("//tr[@class='sell']")
          .map do |tr|
          [
            Amount.new(tr.xpath('./td[2]').text.gsub(',', ''), 'KRW_X'),
            Amount.new(tr.xpath('./td[3]').text, 'BTC_X')
          ]
        end.reverse.map do |price,amount|
          {
            'price' => price,
            'taker_gets_funded' => amount,
            'taker_pays_funded' => price * amount
          }
        end
      rescue
        retry
      end
    end

    module Exchange
      def self.extended(mod)
        [
          [Happy::Currency::KRW_X, Happy::Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:exchange_xcoin)
        end
        [
          [Happy::Currency::BTC_X, Happy::Currency::BTC_B2R]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xcoin)
        end
      end

      Capybara.current_driver = :poltergeist
      include Capybara::DSL

      def last_order_status
        Happy.logger.debug { 'last_order_status' }
        loop do
          Happy.logger.debug { 'loop' }
          visit 'https://www.xcoin.co.kr/u2/US202'
          Happy.logger.debug { 'Parse' }
          stat = find(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr[last()]/td[7]').text
          break if stat == '완료'
          sleep 2
        end
        krw_x = find(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr[last()]/td[4]').text
        btc_x = find(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr[last()]/td[5]').text
        btc_x_fee = find(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr[last()]/td[6]').text
        krw_x = Amount.new(krw_x.gsub(',', ''), 'KRW_X')
        btc_x = Amount.new(btc_x, 'BTC_X')
        btc_x_fee = Amount.new(btc_x_fee, 'BTC_X')
        btc_x -= btc_x_fee
        Happy.logger.debug { 'last_order_status finished' }
        result = AmountHash.new.tap do |ah|
          ah.apply(-krw_x)
          ah.apply(btc_x)
        end
        return result
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        retry
      end

      def exchange_xcoin_impl(amount, counter)
        # TODO: assert amount and counter
        Happy.logger.debug { 'exchange_xcoin' }
        btc_x = value_shift(amount, counter)
        Happy.logger.debug { "btc_x: #{btc_x}" }
        visit 'https://www.xcoin.co.kr/u2/US202'
        Happy.logger.debug { 'Fill' }
        fill_in 'traPwNo', with: xcoin_password2
        check 'gen'
        fill_in 'btcQty', with: btc_x['value'].to_s('F')
        # TODO: set price high
        # check 'auto_price'
        high_btc = find(:xpath, '//tr[@class="sell"][1]/td[2]').text
        fill_in 'btcAmtComma', with: high_btc
        find(:xpath, '//p[@class="btn_org"]').click
        find(:css, '._wModal_btn_yes').click
        Happy.logger.debug { 'exchange_xcoin finished' }
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        retry
      end

      def exchange_xcoin(amount, counter)
        # TODO: assert amount and counter
        exchange_xcoin_impl(amount, counter)
        last_order_status
      end

      def send_xcoin(amount, counter)
        # TODO: assert counter
        destination_address = ENV['BTC2RIPPLE_ADDRESS']

        Happy.logger.debug { 'send_xcoin' }
        visit 'https://www.xcoin.co.kr/u3/US302'
        btc_value = amount['value'].to_s('F')
        Happy.logger.debug { "btc_value: #{btc_value}" }
        fill_in 'btcOutAmt', with: btc_value
        fill_in 'btcOutAdd', with: destination_address
        fill_in 'traPwNo', with: xcoin_password2
        Happy.logger.debug { 'xcoin_sms_validation_code set' }
        MShard::MShard.new.set(
          id: 'xcoin_sms_validation_code',
          contents: '')
        find(:xpath, '//div[text()="인증요청"]').click
        find(:css, '._wModal_btn_yes').click
        Happy.logger.debug { 'xcoin_sms_validation_code loop start' }
        sms = loop do
          sleep 1
          begin
            Happy.logger.debug { 'xcoin_sms_validation_code get' }
            result = MShard::MShard.new.get('xcoin_sms_validation_code')
            Happy.logger.debug { "xcoin_sms_validation_code get: #{result.inspect}" }
            break result unless result.empty?
          rescue => e
            Happy.logger.warn { e.class }
            Happy.logger.warn { e }
            Happy.logger.warn { e.backtrace.join("\n") }
          end
        end
        Happy.logger.debug { 'xcoin_sms_validation_code loop end' }
        fill_in 'smsKeyTmp', with: sms
        find(:xpath, '//p[@class="btn_org"]').click
        find(:css, '._wModal_btn_yes').click
        Happy.logger.debug { 'send_xcoin finished' }

        result = AmountHash.new.tap do |ah|
          ah.apply(-amount)
          ah.apply(
            Amount.new(amount['value'], counter) -
            Amount.new(Amount::BTC_FEE, counter))
        end
        return result
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        retry
      end
    end
  end
end
