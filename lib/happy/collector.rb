require 'happy/xrp'

module Happy
  class Collector
    def initialize
      @logstash = Happy.logstash.with(type: 'market_prices')
    end

    def taint_eop list
      list.last[:price_count] = list.size
    end

    def worker
      Happy::Worker.new.tap do |worker|
        worker.extend(Happy::XRP::Information)
        worker.extend(Happy::Worker::Market)
        worker.extend(Happy::XRP::Market)
        worker.extend(Happy::XCoin::Market)
      end
    end

    def log_market_impl(base, counter)
      asks = worker.market(base, counter)
      taint_eop(asks)
      Happy.logger.debug { "Count of asks(#{base}, #{counter}): #{asks.size}" }
      @logstash.at_once.stash_all(asks)
    end

    def log_market
      [
        [Currency::KRW_X, BTC_X],
        [Currency::BTC_P, Currency::XRP],
        [Currency::XRP, Currency::KRW_P]
      ].each { |base,counter| log_market_impl(base, counter) }
    end
  end
end
