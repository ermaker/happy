require 'happy/xrp'

module Happy
  class Collector
    def taint_eop list
      list.last[:price_count] = list.size
    end

    def market_worker
      Happy::Worker.new.tap do |worker|
        worker.extend(Happy::XRP::Information)
        worker.extend(Happy::Worker::Market)
        worker.extend(Happy::XCoin::Market)
        worker.extend(Happy::XRP::Market)
      end
    end

    def log_market_impl(base, counter)
      asks = market_worker.market(base, counter)
      taint_eop(asks)
      Happy.logger.debug { "Count of asks(#{base}, #{counter}): #{asks.size}" }
      Happy.logstash.with(type: 'market_prices')
        .at_once.stash_all(asks)
    end

    def log_market
      [
        [Currency::KRW_X, Currency::BTC_X],
        [Currency::BTC_P, Currency::XRP],
        [Currency::XRP, Currency::KRW_P]
      ].each { |base,counter| log_market_impl(base, counter) }
    end

    def balance_worker
      Happy::Worker.new.tap do |worker|
        worker.extend(Happy::XCoin::Information)
        worker.extend(Happy::XRP::Information)
        worker.extend(Happy::Worker::Balance)
        worker.extend(Happy::XCoin::Balance)
        worker.extend(Happy::XRP::Balance)
      end
    end

    def log_balances
      balances = balance_worker.balance(
        Currency::KRW_X,
        Currency::BTC_X,
        Currency::BTC_P,
        Currency::XRP,
        Currency::KRW_P
      )
      Happy.logstash.with(type: 'balances')
        .at_once.stash_all(balances)
    end
  end
end
