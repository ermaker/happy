require 'happy/xrp'

module Happy
  class Collector
    def log_market_xrp_impl(base, counter)
      xrp = XRP.new(ENV['XRP_ADDRESS'])
      asks = xrp.market(base, counter)
      Happy.logger.debug { "Count of asks(#{base}, #{counter}): #{asks.size}" }
      Happy.logstash.with(type: 'test').at_once.stash_all(asks)
    end

    def log_market_xrp
      log_market_xrp_impl(Currency::BTC_P, Currency::XRP)
      log_market_xrp_impl(Currency::XRP, Currency::KRW_P)
    end

    def log_market_xcoin
      xcoin = XCoin.new
      asks = xcoin.market
      Happy.logger.debug { "Count of asks(XCoin): #{asks.size}" }
      Happy.logstash.with(type: 'test').at_once.stash_all(asks)
    end
  end
end
