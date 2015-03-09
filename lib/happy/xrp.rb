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

    module Market
      def self.extended(mod)
        [
          [Happy::Currency::BTC_P, Happy::Currency::XRP],
          [Happy::Currency::XRP, Happy::Currency::KRW_P]
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
          [Happy::Currency::BTC_P, Happy::Currency::XRP],
          [Happy::Currency::XRP, Happy::Currency::KRW_P]
        ].each do |base,counter|
          mod.proc_market[[base, counter]] = mod.method(:market_xrp)
        end
      end

      def place_order(amount, counter_amount)
        body = {
          secret: xrp_secret,
          order: {
            type: 'buy',
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
        [Currency::XRP, Currency::KRW_P] =>
        Amount.new('5.0', 'KRW_P')
      }

      def exchange_xrp(amount, counter)
        counter_amount = PRICE[[amount.currency, counter]] * amount
        hash = place_order(amount, counter_amount)['hash']
        result = AmountHash.new.tap do |ah|
          order_transaction(hash)['balance_changes']
            .to_objectify.each do |amount|
            ah.apply(amount)
          end
        end
        result
      end
    end
  end
end
