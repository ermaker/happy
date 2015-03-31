require 'phantomjs/poltergeist'
require 'httparty'
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
    Capybara.register_driver(:poltergeist) do |app|
      Capybara::Poltergeist::Driver.new(
        app,
        phantomjs: Phantomjs.path,
        js_errors: false,
        timeout: 90,
        phantomjs_options: PHANTOMJS_OPTIONS
      )
    end

    module Information
      attr_accessor :xcoin_user, :xcoin_password, :xcoin_password2
      attr_accessor :xcoin_session

      def self.extended(mod)
        mod.xcoin_user = ENV['XCOIN_USER']
        mod.xcoin_password = ENV['XCOIN_PASSWORD']
        mod.xcoin_password2 = ENV['XCOIN_PASSWORD2']
        mod.xcoin_session = Capybara::Session.new(:poltergeist)
      end

      include Capybara::DSL

      def xcoin_not_found(*args)
        xcoin_session.find(*args)
        return false
      rescue Capybara::ElementNotFound
        return true
      rescue
        return false
      end

      def xcoin_ensure_login
        Happy.logger.debug { 'xcoin_ensure_login' }
        xcoin_session.visit 'https://www.xcoin.co.kr/u1/US101'
        if xcoin_not_found(:css, '.gnb_s1') && xcoin_session.find(:css, '.gnb')
          Happy.logger.debug { 'already logged in' }
          return
        end
        Happy.logger.debug { 'Fill username and password' }
        xcoin_session.fill_in 'j_username', with: xcoin_user
        xcoin_session.fill_in 'j_password', with: xcoin_password
        Happy.logger.debug { 'Submit' }
        xcoin_session.find(:xpath, '//p[@class="btn_org"]').click
        Happy.logger.debug { 'xcoin_ensure_login finished' }
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        sleep 0.3
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
        data = xcoin_session.all(:xpath, '//div[@id="snb"]/ul/li').map(&:text)
        AmountHash.new.apply(
          data[1].currency('BTC_X'),
          data[2].currency('KRW_X')
        )
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        sleep 0.3
        retry
      end
    end

    module Market
      def self.extended(mod)
        [
          [Currency::KRW_X, Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_market[[base, counter]] = mod.method(:market_xcoin)
        end
        [
          [Currency::BTC_X, Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_market[[base, counter]] = mod.method(:market_xcoin_reverse)
        end
      end

      def market_xcoin_json
        JSON.parse(HTTParty.get('https://www.xcoin.co.kr/json/marketStatJson', headers: { 'X-Requested-With' => 'XMLHttpRequest' }))
      end

      def market_xcoin(_base, _counter)
        # TODO: ensure base and counter
        market = market_xcoin_json
        market[0, market.size/2].map do |m|
          [
            m['BUY_KRW'].currency('KRW_X'),
            m['BUY_BTC'].currency('BTC_X')
          ]
        end.reverse.map do |price,amount|
          {
            'price' => price,
            'taker_gets_funded' => amount,
            'taker_pays_funded' => price * amount
          }
        end
      rescue
        sleep 0.3
        retry
      end

      def market_xcoin_reverse(_base, _counter)
        # TODO: ensure base and counter
        market = market_xcoin_json
        market[market.size/2, market.size/2].map do |m|
          [
            m['BUY_KRW'].currency('KRW_X'),
            m['BUY_BTC'].currency('BTC_X')
          ]
        end.map do |price,amount|
          {
            'price' => 1.currency('BTC_X') / price,
            'taker_gets_funded' => price * amount,
            'taker_pays_funded' => amount
          }
        end
      rescue
        sleep 0.3
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
          [Currency::BTC_X, Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:exchange_xcoin_reverse)
        end
        [
          [Currency::BTC_X, Currency::BTC_B2R],
          [Currency::BTC_X, Currency::BTC_BS]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xcoin_btc)
        end
        [
          [Currency::KRW_X, Currency::KRW_R]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xcoin_krw)
        end
        [
          [Currency::KRW_X, Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_xcoin_limited)
        end
        [
          [Currency::BTC_X, Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_xcoin)
        end
      end

      include Capybara::DSL

      def xcoin_order_status
        xcoin_session.visit 'https://www.xcoin.co.kr/u2/US202'
        xcoin_session.all(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr')[1..-1]
          .reverse
          .map { |tr| tr.all(:xpath, './/td') }
          .select { |tr| tr.size == 8 }
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
        sleep 0.3
        retry
      end

      def exchange_xcoin_history
        xcoin_session.visit 'https://www.xcoin.co.kr/u2/US204'
        xcoin_session.all(:xpath, '//table[@class="g_table_list"][2]//tr')[1..-1]
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
        sleep 0.3
        retry
      end

      def exchange_xcoin_impl(amount, counter)
        # TODO: assert amount and counter
        Happy.logger.debug { 'exchange_xcoin_impl' }
        btc_x = value_shift(amount, counter)
        Happy.logger.debug { "btc_x: #{btc_x}" }
        xcoin_session.visit 'https://www.xcoin.co.kr/u2/US202'
        Happy.logger.debug { 'Fill' }
        xcoin_session.fill_in 'traPwNo', with: xcoin_password2
        xcoin_session.check 'gen'
        xcoin_session.fill_in 'btcQty', with: btc_x['value'].floor(8).to_s('F')
        high_btc = xcoin_session.find(:xpath, '//tr[@class="sell"][1]/td[2]').text
        xcoin_session.fill_in 'btcAmtComma', with: high_btc
        xcoin_session.find(:xpath, '//p[@class="btn_org"]').click
        xcoin_session.find(:css, '._wModal_btn_yes').click
        Happy.logger.debug { 'exchange_xcoin_impl finished' }
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        sleep 0.3
        retry
      end

      def exchange_xcoin_history_diff filter
        xcoin_ensure_login
        pivot_time = exchange_xcoin_history[0][0]
        retval = yield
        ah = AmountHash.new.apply(
          exchange_xcoin_history.take_while do |record|
            record[0] > pivot_time
          end.select(&filter)
        )
        [ah, retval]
      end

      def exchange_xcoin_order(order_status)
        status_pivot = order_status.call[0]
        Happy.logger.debug { "Status Pivot: #{status_pivot}" }
        try_total = 30
        try_total.times do
          yield
          (180 / 2).times do
            # status_now = order_status.call.take_while do |record|
            order_status_ = order_status.call
            Happy.logger.debug { "Order Status: #{order_status_}" }
            status_now = order_status_.take_while do |record|
              record != status_pivot
            end
            return status_now[0][2] if
              status_now.one? && status_now[0][1] == '완료'
            Happy.logger.debug { "No correct order status: #{status_now}" }
            if status_now.size > 1
              MShard::MShard.new.set_safe(
                pushbullet: true,
                channel_tag: 'morder_process',
                type: 'note',
                title: 'Fail: Too many order status',
                body: "#{status_now}"
              )
              fail "Too many order status: #{status_now}"
            end
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
        MShard::MShard.new.set_safe(
          pushbullet: true,
          channel_tag: 'morder_process',
          type: 'note',
          title: 'Fail: Exchange XCoin',
          body: "#{try_total} tried, but failed"
        )
        fail "#{try_total} tried, but exchange XCoin failed."
      end

      def exchange_xcoin(amount, counter)
        # TODO: assert amount and counter
        ah, status_ah =
          exchange_xcoin_history_diff(
            ->(record) { record[1] == '구매완료' }
          ) do
            exchange_xcoin_order(-> { xcoin_order_status }) do
              exchange_xcoin_impl(amount, counter)
            end
          end

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
        ah
      end

      def xcoin_order_status_reverse
        xcoin_session.visit 'https://www.xcoin.co.kr/u2/US203'
        xcoin_session.all(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr')[1..-1]
          .reverse
          .map { |tr| tr.all(:xpath, './/td') }
          .select { |tr| tr.size == 8 }
          .map do |tr|
            [
              tr[0].text,
              tr[6].text,
              AmountHash.new.apply(
                tr[3].text.currency('KRW_X'),
                tr[4].text.currency('BTC_X'),
                -tr[5].text.currency('KRW_X')
              )
            ]
        end
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        sleep 0.3
        retry
      end

      def exchange_xcoin_impl_reverse_impl(amount, _counter)
        # TODO: assert amount and counter
        Happy.logger.debug { 'exchange_xcoin_impl_reverse' }
        btc_x = amount
        Happy.logger.debug { "btc_x: #{btc_x}" }
        xcoin_session.visit 'https://www.xcoin.co.kr/u2/US203'
        Happy.logger.debug { 'Fill' }
        xcoin_session.fill_in 'traPwNo', with: xcoin_password2
        yield
        xcoin_session.fill_in 'btcQty', with: btc_x['value'].floor(8).to_s('F')
        low_btc = xcoin_session.find(:xpath, '//tr[@class="buying"][last()]/td[2]').text
        xcoin_session.fill_in 'btcAmtComma', with: low_btc
        xcoin_session.find(:xpath, '//p[@class="btn_green"]').click
        xcoin_session.find(:css, '._wModal_btn_yes').click
        Happy.logger.debug { 'exchange_xcoin_impl_reverse finished' }
      end

      def exchange_xcoin_impl_reverse(amount, counter)
        currency = amount.currency
        loop do
          begin
            return exchange_xcoin_impl_reverse_impl(amount, counter) do
              xcoin_session.check 'misuYnTmp'
            end
          rescue => e
            Happy.logger.warn { e.class }
            Happy.logger.warn { e }
            Happy.logger.warn { e.backtrace.join("\n") }
            sleep 0.3
          end
          if amount <= balance(currency)[currency]
            begin
              return exchange_xcoin_impl_reverse_impl(amount, counter) do
                xcoin_session.check 'gen'
              end
            rescue => e
              Happy.logger.warn { e.class }
              Happy.logger.warn { e }
              Happy.logger.warn { e.backtrace.join("\n") }
              sleep 0.3
            end
          end
          sleep 10
        end
      end

      def exchange_xcoin_reverse(amount, counter)
        # TODO: assert amount and counter
        ah, status_ah =
          exchange_xcoin_history_diff(
            ->(record) { record[1] == '판매완료' }
          ) do
            exchange_xcoin_order(-> { xcoin_order_status_reverse }) do
              exchange_xcoin_impl_reverse(amount, counter)
            end
          end

        unless -ah[Currency::BTC_X] == status_ah[Currency::BTC_X]
          Happy.logger.warn { "Order Status != History: #{status_ah} #{ah}" }
          MShard::MShard.new.set(
            pushbullet: true,
            channel_tag: 'morder_process',
            type: 'note',
            title: 'Order Status != History',
            body: "Order Status: #{status_ah}\nHistory: #{ah}"
          )
        end
        ah
      end

      SEND_XCOIN_DESTINATION_ADDRESS = {
        Currency::BTC_B2R => ENV['BTC2RIPPLE_ADDRESS'],
        Currency::BTC_BS => ENV['BITSTAMP_ADDRESS']
      }

      def send_xcoin_btc_impl(amount, counter)
        Happy.logger.debug { 'send_xcoin_btc_impl' }
        destination_address =  SEND_XCOIN_DESTINATION_ADDRESS[counter.currency]
        fail counter.to_s if destination_address.nil?
        xcoin_session.visit 'https://www.xcoin.co.kr/u3/US302'
        btc_value = amount['value'].to_s('F')
        Happy.logger.debug { "btc_value: #{btc_value}" }
        xcoin_session.fill_in 'btcOutAmt', with: btc_value
        xcoin_session.fill_in 'btcOutAdd', with: destination_address
        xcoin_session.fill_in 'traPwNo', with: xcoin_password2
        Happy.logger.debug { 'xcoin_sms_validation_code set' }
        MShard::MShard.new.set_safe(
          id: 'xcoin_sms_validation_code',
          contents: '')
        xcoin_session.find(:xpath, '//div[text()="인증요청"]').click
        xcoin_session.find(:css, '._wModal_btn_yes').click
        Happy.logger.debug { 'xcoin_sms_validation_code loop start' }
        sms =
          catch do |sms_done|
            (300 / 1).times do
              sleep 1
              begin
                Happy.logger.debug { 'xcoin_sms_validation_code get' }
                result = MShard::MShard.new.get_safe('xcoin_sms_validation_code')
                throw(sms_done, result) unless result.nil? || result.empty?
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
        xcoin_session.fill_in 'smsKeyTmp', with: sms
        xcoin_session.find(:xpath, '//p[@class="btn_org"]').click
        xcoin_session.find(:css, '._wModal_btn_yes').click
        Happy.logger.debug { 'send_xcoin_btc_impl finished' }
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        sleep 0.3
        retry
      end

      def send_xcoin_btc(amount, counter)
        amount = amount.randomify(6).floor(8)
        xcoin_ensure_login
        history_ = catch do |history_done|
          history_pivot_time = exchange_xcoin_history[0][0]
          loop do
            send_xcoin_btc_impl(amount, counter)
            (60 / 2).times do
              history_ = exchange_xcoin_history
                .take_while do |record|
                  record[0] > history_pivot_time
              end.select do |record|
                record[1] == 'BTC출금중'
              end
              throw(history_done, history_) unless history_.empty?
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

      def send_xcoin_krw(amount, counter)
        # xXX: This is just simulated value
        AmountHash.new.apply(
          -amount,
          counter.with(amount),
          -Amount::XCOIN_WITHDRAWAL_FEE
        )
      end

      def wait_xcoin_limited(amount, _counter)
        return AmountHash.new if wait(amount, time: 120)

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

      def wait_xcoin(amount, _counter)
        wait(amount)
        AmountHash.new
      end
    end

    module SimulatedExchange
      def self.extended(mod)
        [
          [Currency::KRW_X, Currency::BTC_X],
          [Currency::BTC_X, Currency::KRW_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:exchange_xcoin_simulated)
        end
        [
          [Currency::BTC_X, Currency::BTC_B2R],
          [Currency::BTC_X, Currency::BTC_BS]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xcoin_btc_simulated)
        end
        [
          [Currency::KRW_X, Currency::KRW_R]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xcoin_krw_simulated)
        end
        [
          [Currency::KRW_X, Currency::KRW_X],
          [Currency::BTC_X, Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_xcoin_simulated)
        end
      end

      def exchange_xcoin_simulated(amount, counter)
        AmountHash.new.apply(
          -amount,
          value_shift(amount, counter) *
            Amount::XCOIN_ANTI_FEE_RATIO
        )
      end

      def send_xcoin_btc_simulated(amount, counter)
        AmountHash.new.apply(
          -amount,
          counter.with(amount),
          -counter.with(Amount::BTC_FEE)
        )
      end

      def send_xcoin_krw_simulated(amount, counter)
        # TODO: ensure amount and counter
        AmountHash.new.apply(
          -amount,
          counter.with(amount)
        )
        # -Amount::XCOIN_WITHDRAWAL_FEE # XXX: Unused value
      end

      def wait_xcoin_simulated(_amount, _counter)
        AmountHash.new
      end
    end
  end
end
