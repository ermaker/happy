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
  end
end
