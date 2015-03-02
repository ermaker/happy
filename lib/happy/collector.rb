require 'happy/xrp'

module Happy
  class Collector
    def log_market_xrp_impl(base, counter)
      xrp = XRP.new(ENV['XRP_ADDRESS'])
      bids = xrp.market(base, counter)
      Happy.logger.debug { "Count of bids(#{base}, #{counter}): #{bids.size}" }
      Happy.logstash.with(type: 'test').at_once.stash_all(bids)
    end
    def log_market_xrp
      log_market_xrp_impl(Currency::BTC_P, Currency::XRP)
      log_market_xrp_impl(Currency::XRP, Currency::KRW_P)
    end
  end
end
