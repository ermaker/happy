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
        [Currency::BTC_BSR, Currency::XRP],
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
        Currency::BTC_BSR,
        Currency::XRP,
        Currency::KRW_P
      )
      Happy.logstash.with(type: 'balances')
        .at_once.stash_all(balances.values)
    end

    def simulated_worker
      Worker.new.tap do |worker|
        worker.extend(Worker::Balance)
        worker.extend(Simulator::Balance)
        worker.extend(Worker::Market)
        worker.extend(Logged::Market)
        worker.extend(Worker::Exchange)
        worker.extend(XCoin::SimulatedExchange)
        worker.extend(B2R::SimulatedExchange)
        worker.extend(XRP::SimulatedExchange)
        worker.extend(PaxMoneta::SimulatedExchange)
      end
    end

    def simple_estimated_benefit(base_worker, krw_r_value)
      worker = simulated_worker
      worker.time = base_worker.time
      worker.cached_market_logged = base_worker.cached_market_logged

      worker.initial_balance = krw_r_value.currency('KRW_R')
      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)
      [
        Currency::KRW_R,
        Currency::KRW_X,
        Currency::KRW_X,
        Currency::BTC_X,
        Currency::BTC_B2R,
        Currency::BTC_P,
        Currency::BTC_P,
        Currency::XRP,
        Currency::KRW_P,
        Currency::KRW_R
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      base_worker.cached_market_logged = worker.cached_market_logged

      {
        algo: 'simple',
        path: 'KRW/XCOIN/B2R/XRP/PAX/KRW',
        benefit: worker.benefit['value'].round(2).to_f,
        percent:
          (worker.benefit / worker.initial_balance * 100)['value']
            .round(2).to_f,
        base: worker.initial_balance['value'].to_i
      }
    end

    def log_simple_estimated_benefit
      base_worker = simulated_worker
      base = 100000
      seb = (base..(40 * base)).step(base).map do |krw_r_value|
        simple_estimated_benefit(base_worker, krw_r_value)
      end
      puts seb.map(&:to_json)
      Happy.logstash.with(type: 'estimated_benefit')
        .at_once.stash_all(seb)
    end
  end
end
