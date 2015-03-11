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

      Capybara.current_driver = :poltergeist
      include Capybara::DSL

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

    module Balance
      def self.extended(mod)
        [
          Happy::Currency::KRW_X,
          Happy::Currency::BTC_X
        ].each do |currency|
          mod.proc_balance[currency] = mod.method(:balance_xcoin)
        end
      end

      Capybara.current_driver = :poltergeist
      include Capybara::DSL

      def balance_xcoin
        xcoin_ensure_login
        data = all(:xpath, '//div[@id="snb"]/ul/li').map(&:text)
        AmountHash.new.tap do |ah|
          ah.apply(Amount.new(data[1], 'BTC_X'))
          ah.apply(Amount.new(data[2].gsub(',', ''), 'KRW_X'))
        end
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
        [
          [Happy::Currency::KRW_X, Happy::Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_xcoin)
        end
        [
          [Happy::Currency::KRW_R, Happy::Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:move_xcoin)
        end
      end

      Capybara.current_driver = :poltergeist
      include Capybara::DSL

      def xcoin_order_status
        visit 'https://www.xcoin.co.kr/u2/US202'
        all(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr')[1..-1]
          .reverse
          .map { |tr| tr.all(:xpath, './/td') }
          .map do |tr|
            [
              tr[0].text,
              tr[6].text,
              AmountHash.new.tap do |ah|
                ah.apply(Amount.new(tr[3].text.gsub(',', ''), 'KRW_X'))
                ah.apply(Amount.new(tr[4].text, 'BTC_X'))
                ah.apply(-Amount.new(tr[5].text, 'BTC_X'))
              end
            ]
        end
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        retry
      end

      def exchange_xcoin_history
        visit 'https://www.xcoin.co.kr/u2/US204'
        all(:xpath, '//table[@class="g_table_list"][2]//tr')[1..-1]
          .map { |tr| tr.all(:xpath, './/td') }
          .map do |tr|
            [tr[1].text, AmountHash.new.tap do |ah|
              ah.apply(Amount.new(tr[2].text.split[0, 2].join, 'BTC_X'))
              ah.apply(Amount.new(tr[3].text.split[0].gsub(',', ''), 'KRW_X'))
            end]
        end
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
        # check 'auto_price'
        # Set price high
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
        xcoin_ensure_login
        history = exchange_xcoin_history[0]
        status = xcoin_order_status[0]
        exchange_xcoin_impl(amount, counter)
        status_ah =
          loop do
            status_ = xcoin_order_status.take_while { |record| record != status }
            break status_[0][2] if status_.one? && status_[0][1] == '완료'
            Happy.logger.debug { "No correct order status: #{status_}" }
            sleep 2
          end
        AmountHash.new.tap do |ah|
          exchange_xcoin_history.take_while { |record| record != history }
            .each { |record| ah.apply_all(record[1]) }
          unless ah[Currency::BTC_X] == status_ah[Currency::BTC_X]
            Happy.logger.warn { "Order Status != History: #{status_ah} #{ah}" }
            MShard::MShard.new.set(
              pushbullet: true,
              channel_tag: 'morder_process',
              type: 'note',
              title: 'Order Status != History',
              body: "Order Status: #{status_ah}\nHistory: #{ah}"
            )
          end
        end
      end

      def send_xcoin_impl(amount, _counter)
        # TODO: assert _counter
        destination_address = ENV['BTC2RIPPLE_ADDRESS'] # FIXME
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
            break result unless result.empty?
          rescue => e
            Happy.logger.warn { e.class }
            Happy.logger.warn { e }
            Happy.logger.warn { e.backtrace.join("\n") }
          end
        end
        Happy.logger.debug { "sms: #{sms}" }
        fill_in 'smsKeyTmp', with: sms
        find(:xpath, '//p[@class="btn_org"]').click
        find(:css, '._wModal_btn_yes').click
        Happy.logger.debug { 'send_xcoin finished' }
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        retry
      end

      def send_xcoin(amount, counter)
        xcoin_ensure_login
        history = exchange_xcoin_history[0]
        send_xcoin_impl(amount, counter)
        history_ah = AmountHash.new.tap do |ah|
          exchange_xcoin_history.take_while { |record| record != history }
            .each { |record| ah.apply_all(record[1]) }
        end
        AmountHash.new.tap do |ah|
          ah.apply(-amount)
          ah.apply(Amount.new(amount['value'], counter))
          ah.apply(-Amount.new(Amount::BTC_FEE, counter))
          unless ah[Currency::BTC_X] == history_ah[Currency::BTC_X]
            Happy.logger.warn { "Expected Status != History: #{ah} #{history_ah}" }
            MShard::MShard.new.set(
              pushbullet: true,
              channel_tag: 'morder_process',
              type: 'note',
              title: 'Expected Status != History',
              body: "Expected Status: #{ah}\nHistory: #{history_ah}"
            )
          end
        end
      end

      def wait_xcoin(amount, _counter)
        wait(amount)
        AmountHash.new
      end

      def move_xcoin(amount, counter)
        AmountHash.new.tap do |ah|
          ah.apply(-amount)
          ah.apply(Amount.new(amount['value'], counter))
        end
      end
    end

    module SimulatedExchange
      def self.extended(mod)
        [
          [Happy::Currency::KRW_X, Happy::Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:exchange_xcoin_simulated)
        end
        [
          [Happy::Currency::BTC_X, Happy::Currency::BTC_B2R]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xcoin_simulated)
        end
        [
          [Happy::Currency::KRW_X, Happy::Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_xcoin_simulated)
        end
        [
          [Happy::Currency::KRW_R, Happy::Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:move_xcoin_simulated)
        end
      end

      def exchange_xcoin_simulated(amount, counter)
        AmountHash.new.tap do |ah|
          ah.apply(-amount)
          ah.apply(
            value_shift(amount, counter) *
            Amount.new(Amount::XCOIN_ANTI_FEE_RATIO, 'BTC_X')
          )
        end
      end

      def send_xcoin_simulated(amount, counter)
        AmountHash.new.tap do |ah|
          ah.apply(-amount)
          ah.apply(Amount.new(amount['value'], counter))
          ah.apply(-Amount.new(Amount::BTC_FEE, counter))
        end
      end

      def wait_xcoin_simulated(_amount, _counter)
        AmountHash.new
      end

      def move_xcoin_simulated(amount, counter)
        AmountHash.new.tap do |ah|
          ah.apply(-amount)
          ah.apply(Amount.new(amount['value'], counter))
        end
      end
    end
  end
end
