require 'httparty'

module Happy
  module XRP
    module Information
      attr_accessor :xrp_address, :xrp_secret

      def self.extended(mod)
        mod.xrp_address = ENV['XRP_ADDRESS']
        mod.xrp_secret = ENV['XRP_SECRET']
      end
    end

    module Balance
      def self.extended(mod)
        [
          Currency::BTC_P,
          Currency::BTC_BSR,
          Currency::XRP,
          Currency::KRW_P
        ].each do |currency|
          mod.proc_balance[currency] = mod.method(:balance_xrp)
        end
      end

      def balance_xrp_impl
        response = HTTParty.get("https://api.ripple.com/v1/accounts/#{xrp_address}/balances")
                   .parsed_response
        fail response.inspect unless response['success']
        response
      end

      def balance_xrp
        AmountHash.new.apply(balance_xrp_impl['balances'])
      end
    end

    module Market
      def self.extended(mod)
        [
          [Currency::BTC_P, Currency::XRP],
          [Currency::BTC_BSR, Currency::XRP],
          [Currency::XRP, Currency::KRW_P]
        ].each do |base,counter|
          mod.proc_market[[base, counter]] = mod.method(:market_xrp)
        end
      end

      def market_xrp_order_book(base, counter)
        limit = 200
        response = HTTParty.get(
          "https://api.ripple.com/v1/accounts/#{xrp_address}/order_book/#{counter}/#{base}",
          query: { limit: limit })
                   .parsed_response
        fail response.inspect unless response['success']
        response
      end

      ASK_WHITE_LIST = %w(price taker_gets_funded taker_pays_funded)

      def market_xrp(base, counter)
        market_xrp_order_book(base, counter)['asks']
          .map { |ask| ask.filter(*ASK_WHITE_LIST) }
          .to_objectify
      end
    end

    module Exchange
      def self.extended(mod)
        [
          [Currency::BTC_P, Currency::XRP],
          [Currency::BTC_BSR, Currency::XRP],
          [Currency::XRP, Currency::KRW_P]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:exchange_xrp)
        end
        [
          [Currency::BTC_P, Currency::BTC_P],
          [Currency::BTC_BSR, Currency::BTC_BSR]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_xrp)
        end
      end

      def place_order(amount, counter_amount)
        body = {
          secret: xrp_secret,
          order: {
            type: 'sell',
            taker_gets: amount,
            taker_pays: counter_amount
          }
        }
        response = HTTParty.post(
          "https://api.ripple.com/v1/accounts/#{xrp_address}/orders",
          query: { validated: true },
          body: body.to_json,
          headers: { 'Content-Type' => 'application/json' })
                   .parsed_response
        fail response.inspect unless response['success']
        response
      end

      def order_transaction(hash)
        response = HTTParty.get(
          "https://api.ripple.com/v1/accounts/#{xrp_address}/orders/#{hash}")
                   .parsed_response
        fail response.inspect unless response['success']
        fail response.inspect unless response['order_changes'].empty?
        response
      end

      PRICE = {
        [Currency::BTC_P, Currency::XRP] =>
        Amount.new('10000.0', 'XRP'),
        [Currency::BTC_BSR, Currency::XRP] =>
        Amount.new('10000.0', 'XRP'),
        [Currency::XRP, Currency::KRW_P] =>
        Amount.new('5.0', 'KRW_P')
      }

      def exchange_xrp(amount, counter)
        counter_amount = PRICE[[amount.currency, counter]] * amount
        hash = place_order(amount, counter_amount)['hash']
        AmountHash.new.apply(
          order_transaction(hash)['balance_changes']
        )
      end

      def wait_xrp(amount, _counter)
        wait(amount)
        AmountHash.new
      end
    end

    module SimulatedExchange
      def self.extended(mod)
        [
          [Currency::BTC_P, Currency::XRP],
          [Currency::BTC_BSR, Currency::XRP],
          [Currency::XRP, Currency::KRW_P]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:exchange_xrp_simulated)
        end
        [
          [Currency::BTC_P, Currency::BTC_P],
          [Currency::BTC_BSR, Currency::BTC_BSR]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_xrp_simulated)
        end
      end

      def exchange_xrp_simulated(amount, counter)
        # FIXME
        anti_fee_ratio =
          case
          when amount.same_currency?(Currency::BTC_P)
            Amount::B2R_RIPPLE_ANTI_FEE_RATIO
          when amount.same_currency?(Currency::BTC_BSR)
            Amount::BITSTAMP_RIPPLE_ANTI_FEE_RATIO
          else
            '1'
          end

        AmountHash.new.apply(
          -amount,
          value_shift(amount, counter) * anti_fee_ratio,
          -Amount::XRP_FEE
        )
      end

      def wait_xrp_simulated(_amount, _counter)
        AmountHash.new
      end
    end
  end
end
