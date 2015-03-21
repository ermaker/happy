require 'phantomjs/poltergeist'
require 'time'

module Happy
  module XCoin
    PHANTOMJS_OPTIONS = [
      '--load-images=no'
    ]
    PHANTOMJS_OPTIONS.push("--proxy=#{ENV['XCOIN_PROXY']}") unless
      ENV['XCOIN_PROXY'].nil? || ENV['XCOIN_PROXY'].empty?
    PHANTOMJS_OPTIONS.push("--proxy-auth=#{ENV['XCOIN_PROXY_AUTH']}") unless
      ENV['XCOIN_PROXY_AUTH'].nil? || ENV['XCOIN_PROXY_AUTH'].empty?
    Capybara.register_driver(:poltergeist_proxy) do |app|
      Capybara::Poltergeist::Driver.new(
        app,
        phantomjs: Phantomjs.path,
        js_errors: false,
        timeout: 90,
        phantomjs_options: PHANTOMJS_OPTIONS
      )
    end
    Capybara.current_driver = :poltergeist_proxy

    module Information
      attr_accessor :xcoin_user, :xcoin_password, :xcoin_password2

      def self.extended(mod)
        mod.xcoin_user = ENV['XCOIN_USER']
        mod.xcoin_password = ENV['XCOIN_PASSWORD']
        mod.xcoin_password2 = ENV['XCOIN_PASSWORD2']
      end

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
          Currency::KRW_X,
          Currency::BTC_X
        ].each do |currency|
          mod.proc_balance[currency] = mod.method(:balance_xcoin)
        end
      end

      include Capybara::DSL

      def balance_xcoin
        xcoin_ensure_login
        data = all(:xpath, '//div[@id="snb"]/ul/li').map(&:text)
        AmountHash.new.apply(
          data[1].currency('BTC_X'),
          data[2].currency('KRW_X')
        )
      end
    end

    module Market
      def self.extended(mod)
        [
          [Currency::KRW_X, Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_market[[base, counter]] = mod.method(:market_xcoin)
        end
      end

      include Capybara::DSL

      def market_xcoin(_base, _counter)
        # TODO: ensure base and counter
        visit 'http://www.xcoin.co.kr'
        Nokogiri.HTML(page.body).xpath("//tr[@class='sell']")
          .map do |tr|
          [
            tr.xpath('./td[2]').text.currency('KRW_X'),
            tr.xpath('./td[3]').text.currency('BTC_X')
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
          [Currency::KRW_X, Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:exchange_xcoin)
        end
        [
          [Currency::BTC_X, Currency::BTC_B2R],
          [Currency::BTC_X, Currency::BTC_BS]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xcoin)
        end
        [
          [Currency::KRW_X, Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_xcoin)
        end
        [
          [Currency::KRW_R, Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:move_xcoin)
        end
      end

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
              AmountHash.new.apply(
                tr[3].text.currency('KRW_X'),
                tr[4].text.currency('BTC_X'),
                -tr[5].text.currency('BTC_X')
              )
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
            [
              Time.parse(tr[1].text),
              tr[0].text,
              AmountHash.new.apply(
                tr[2].text.split[0, 2].join.currency('BTC_X'),
                tr[3].text.split[0].currency('KRW_X')
              )
            ]
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
        history_pivot_time = exchange_xcoin_history[0][0]
        status_ah = catch(:status) do
          status = xcoin_order_status[0]
          loop do
            exchange_xcoin_impl(amount, counter)
            (60 / 2).times do
              status_ = xcoin_order_status.take_while do |record|
                record != status
              end
              throw(:status, status_[0][2]) if
                status_.one? && status_[0][1] == '완료'
              Happy.logger.debug { "No correct order status: #{status_}" }
              sleep 2
            end
            Happy.logger.warn { 'No correct order status. Exchange XCoin again.' }
            MShard::MShard.new.set(
              pushbullet: true,
              channel_tag: 'morder_process',
              type: 'note',
              title: 'Exchange XCoin again',
              body: 'No correct order status'
            )
          end
        end
        AmountHash.new.tap do |ah|
          balances = exchange_xcoin_history.take_while do |record|
            record[0] > history_pivot_time
          end.select do |record|
            record[1] == '구매완료'
          end
          ah.apply(balances)
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

      DESTINATION_ADDRESS = {
        Currency::BTC_B2R => ENV['BTC2RIPPLE_ADDRESS'],
        Currency::BTC_BS => ENV['BITSTAMP_ADDRESS']
      }

      def send_xcoin_impl(amount, counter)
        Happy.logger.debug { 'send_xcoin' }
        destination_address =  DESTINATION_ADDRESS[counter.currency]
        fail counter.to_s if destination_address.nil?
        visit 'https://www.xcoin.co.kr/u3/US302'
        btc_value = amount['value'].to_s('F')
        Happy.logger.debug { "btc_value: #{btc_value}" }
        fill_in 'btcOutAmt', with: btc_value
        fill_in 'btcOutAdd', with: destination_address
        fill_in 'traPwNo', with: xcoin_password2
        Happy.logger.debug { 'xcoin_sms_validation_code set' }
        MShard::MShard.new.set_safe(
          id: 'xcoin_sms_validation_code',
          contents: '')
        find(:xpath, '//div[text()="인증요청"]').click
        find(:css, '._wModal_btn_yes').click
        Happy.logger.debug { 'xcoin_sms_validation_code loop start' }
        sms =
          catch(:sms_done) do
            (30 / 1).times do
              sleep 1
              begin
                Happy.logger.debug { 'xcoin_sms_validation_code get' }
                result = MShard::MShard.new.get_safe('xcoin_sms_validation_code')
                throw(:sms_done, result) unless result.nil? || result.empty?
              rescue => e
                Happy.logger.warn { e.class }
                Happy.logger.warn { e }
                Happy.logger.warn { e.backtrace.join("\n") }
              end
            end
            MShard::MShard.new.set(
              pushbullet: true,
              channel_tag: 'morder_process',
              type: 'note',
              title: 'No SMS response',
              body: 'No SMS response'
            )
            fail 'No SMS response'
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
        history_ = catch(:history) do
          history_pivot_time = exchange_xcoin_history[0][0]
          loop do
            send_xcoin_impl(amount, counter)
            (60 / 2).times do
              history_ = exchange_xcoin_history
                .take_while do |record|
                  record[0] > history_pivot_time
              end.select do |record|
                record[1] == 'BTC출금중'
              end
              throw(:history, history_) unless history_.empty?
              Happy.logger.debug { 'No record found on send xcoin' }
              sleep 2
            end
            Happy.logger.warn { 'No history changed. Send XCoin again.' }
            MShard::MShard.new.set(
              pushbullet: true,
              channel_tag: 'morder_process',
              type: 'note',
              title: 'Send XCoin again',
              body: 'No history changed'
            )
          end
        end
        history_ah = AmountHash.new.apply(history_)
        AmountHash.new.tap do |ah|
          ah.apply(
            -amount,
            counter.with(amount),
            -counter.with(Amount::BTC_FEE)
          )
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
        return AmountHash.new if wait(amount, time: 30)

        message_detail = "#{amount.to_human}, but #{balance(amount.currency)[amount.currency].to_human(round: 2)}"
        message_brief = 'Not enough KRW_X'
        Happy.logger.error do
          "#{message_brief}: #{message_detail}"
        end
        MShard::MShard.new.set(
          pushbullet: true,
          channel_tag: 'morder_process',
          type: 'note',
          title: message_brief,
          body: message_detail
        )
        fail message_brief
      end

      def move_xcoin(amount, counter)
        AmountHash.new.apply(
          -amount,
          counter.with(amount)
        )
      end
    end

    module SimulatedExchange
      def self.extended(mod)
        [
          [Currency::KRW_X, Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:exchange_xcoin_simulated)
        end
        [
          [Currency::BTC_X, Currency::BTC_B2R],
          [Currency::BTC_X, Currency::BTC_BS]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xcoin_simulated)
        end
        [
          [Currency::KRW_X, Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_xcoin_simulated)
        end
        [
          [Currency::KRW_R, Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:move_xcoin_simulated)
        end
      end

      def exchange_xcoin_simulated(amount, counter)
        AmountHash.new.apply(
          -amount,
          value_shift(amount, counter) *
            Amount::XCOIN_ANTI_FEE_RATIO
        )
      end

      def send_xcoin_simulated(amount, counter)
        AmountHash.new.apply(
          -amount,
          counter.with(amount),
          -counter.with(Amount::BTC_FEE)
        )
      end

      def wait_xcoin_simulated(_amount, _counter)
        AmountHash.new
      end

      def move_xcoin_simulated(amount, counter)
        AmountHash.new.apply(
          -amount,
          counter.with(amount)
        )
      end
    end
  end
end
