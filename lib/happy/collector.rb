require 'timeout'
require 'happy/xrp'

module Happy
  class Collector
    def taint_bunch_size bunch
      bunch.last[:bunch_size] = bunch.size
    end

    def taint_best_price bunch
      bunch.min_by { |item| item[:price].to_objectify }[:best] = true
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
      taint_bunch_size(asks)
      taint_best_price(asks)
      Happy.logger.debug { "Count of asks(#{base}, #{counter}): #{asks.size}" }
      Happy.logstash.with(type: 'market_prices')
        .at_once.stash_all(asks)
    end

    def log_market_xcoin
      [
        [Currency::KRW_X, Currency::BTC_X],
        [Currency::BTC_X, Currency::KRW_X]
      ].each { |base,counter| log_market_impl(base, counter) }
    end

    def log_market_xrp
      [
        [Currency::BTC_P, Currency::XRP],
        [Currency::BTC_BSR, Currency::XRP],
        [Currency::XRP, Currency::KRW_P],
        [Currency::XRP, Currency::BTC_P],
        [Currency::XRP, Currency::BTC_BSR],
        [Currency::KRW_P, Currency::XRP]
      ].each { |base,counter| log_market_impl(base, counter) }
    end

    def log_market
      Timeout::timeout(60) do
        log_market_xrp
        log_market_xcoin
      end
    end

    def balance_worker
      Happy::Worker.new.tap do |worker|
        worker.extend(Happy::XCoin::Information)
        worker.extend(Happy::BitStamp::Information)
        worker.extend(Happy::XRP::Information)
        worker.extend(Happy::Worker::Balance)
        worker.extend(Happy::XCoin::Balance)
        worker.extend(Happy::BitStamp::Balance)
        worker.extend(Happy::XRP::Balance)
      end
    end

    def log_balances
      balances = balance_worker.balance(
        Currency::KRW_X,
        Currency::BTC_X,
        Currency::BTC_BS,
        Currency::BTC_P,
        Currency::BTC_BSR,
        Currency::XRP,
        Currency::KRW_P
      )
      Happy.logstash.with(type: 'balances')
        .at_once.stash_all(balances.values)
    end

    LOG_DELAY = 1 * 60 * 60 + 10 * 60
    LOG_BASE = 100000
    LOG_RANGE_TIMES = 40
    LOG_RANGE = (LOG_BASE..LOG_RANGE_TIMES * LOG_BASE).step(LOG_BASE)

    def taint_best_benefit bunch
      bunch.max_by { |item| item[:benefit] }[:best] = true
    end

    def simulated_worker
      Worker.new.tap do |worker|
        worker.extend(Worker::Balance)
        worker.extend(Simulator::Balance)
        worker.extend(Worker::Market)
        worker.extend(Logged::Market)
        worker.extend(Worker::Exchange)
        worker.extend(Real::SimulatedExchange)
        worker.extend(XCoin::SimulatedExchange)
        worker.extend(B2R::SimulatedExchange)
        worker.extend(BitStamp::SimulatedExchange)
        worker.extend(XRP::SimulatedExchange)
        worker.extend(XRPSend::SimulatedExchange)
      end
    end

    def benefit_result worker, **default
      default.merge(
        benefit: worker.benefit['value'].round(2).to_f,
        percent:
          (worker.benefit / worker.initial_balance * 100)['value']
            .round(2).to_f,
        base: worker.initial_balance['value'].to_i
      )
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
        Currency::BTC_BS,
        Currency::BTC_BS,
        Currency::BTC_BSR,
        Currency::BTC_BSR,
        Currency::XRP,
        Currency::KRW_P,
        Currency::KRW_R
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      base_worker.cached_market_logged = worker.cached_market_logged

      benefit_result(
        worker,
        algo: 'simple',
        path: 'KRW/XCOIN/BS/XRP/PAX/KRW'
      )
    end

    def log_simple_estimated_benefit
      base_worker = simulated_worker
      seb = LOG_RANGE.map do |krw_r_value|
        simple_estimated_benefit(base_worker, krw_r_value)
      end
      taint_best_benefit(seb)
      Happy.logstash.with(type: 'estimated_benefit')
        .at_once.stash_all(seb)
    end

    def simple_estimated_benefit_b2r(base_worker, krw_r_value)
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

      benefit_result(
        worker,
        algo: 'simple',
        path: 'KRW/XCOIN/B2R/XRP/PAX/KRW'
      )
    end

    def log_simple_estimated_benefit_b2r
      base_worker = simulated_worker
      seb = LOG_RANGE.map do |krw_r_value|
        simple_estimated_benefit_b2r(base_worker, krw_r_value)
      end
      taint_best_benefit(seb)
      Happy.logstash.with(type: 'estimated_benefit')
        .at_once.stash_all(seb)
    end

    def simple_estimated_benefit_reversed(base_worker, krw_r_value)
      worker = simulated_worker
      worker.time = base_worker.time
      worker.cached_market_logged = base_worker.cached_market_logged

      worker.initial_balance = krw_r_value.currency('KRW_R')
      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)
      [
        Currency::KRW_R,
        Currency::KRW_P,
        Currency::KRW_P,
        Currency::XRP,
        Currency::BTC_BSR,
        Currency::BTC_BS,
        Currency::BTC_BS,
        Currency::BTC_X,
        Currency::BTC_X,
        Currency::KRW_X
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      # Do not withdrawal
      worker.local_balances.apply(
        -worker.local_balances[Currency::KRW_X],
        worker.local_balances[Currency::KRW_X]['value'].currency(Currency::KRW_R)
      )

      base_worker.cached_market_logged = worker.cached_market_logged

      benefit_result(
        worker,
        algo: 'simple',
        path: 'KRW/PAX/XRP/BS/XCOIN/KRW'
      )
    end

    def log_simple_estimated_benefit_reversed
      base_worker = simulated_worker
      seb = LOG_RANGE.map do |krw_r_value|
        simple_estimated_benefit_reversed(base_worker, krw_r_value)
      end
      taint_best_benefit(seb)
      Happy.logstash.with(type: 'estimated_benefit')
        .at_once.stash_all(seb)
    end

    def simple_estimated_benefit_recycled(base_worker, krw_r_value)
      worker = simulated_worker
      worker.time = base_worker.time
      worker.cached_market_logged = base_worker.cached_market_logged

      initial_balance = krw_r_value.currency('KRW_R')
      worker.initial_balance = initial_balance

      # Use inner amount
      worker.local_balances.apply(-initial_balance)
      worker.local_balances.apply(initial_balance['value'].currency('KRW_P'))

      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)
      [
        Currency::KRW_P,
        Currency::KRW_P,
        Currency::XRP,
        Currency::BTC_BSR,
        Currency::BTC_BS,
        Currency::BTC_BS,
        Currency::BTC_X,
        Currency::BTC_X,
        Currency::KRW_X
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      # Do not withdrawal
      worker.local_balances.apply(
        -worker.local_balances[Currency::KRW_X],
        worker.local_balances[Currency::KRW_X]['value'].currency(Currency::KRW_R)
      )

      base_worker.cached_market_logged = worker.cached_market_logged

      benefit_result(
        worker,
        algo: 'simple',
        path: 'PAX/XRP/BS/XCOIN'
      )
    end

    def log_simple_estimated_benefit_recycled
      base_worker = simulated_worker
      seb = LOG_RANGE.map do |krw_r_value|
        simple_estimated_benefit_recycled(base_worker, krw_r_value)
      end
      taint_best_benefit(seb)
      Happy.logstash.with(type: 'estimated_benefit')
        .at_once.stash_all(seb)
    end

    def delayed_estimated_benefit(base_worker, krw_r_value, delay)
      worker = simulated_worker
      worker.cached_market_logged = base_worker.cached_market_logged

      worker.time = base_worker.time - delay
      Happy.logger.debug { "Worker time: #{worker.time}" }

      worker.initial_balance = krw_r_value.currency('KRW_R')
      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)
      [
        Currency::KRW_R,
        Currency::KRW_X,
        Currency::KRW_X,
        Currency::BTC_X,
        Currency::BTC_BS
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      worker.time = base_worker.time
      Happy.logger.debug { "Worker time: #{worker.time}" }

      [
        Currency::BTC_BS,
        Currency::BTC_BS,
        Currency::BTC_BSR,
        Currency::BTC_BSR,
        Currency::XRP,
        Currency::KRW_P,
        Currency::KRW_R
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      base_worker.cached_market_logged = worker.cached_market_logged

      benefit_result(
        worker,
        algo: 'delayed',
        path: 'KRW/XCOIN/BS/XRP/PAX/KRW'
      )
    end

    def log_delayed_estimated_benefit
      base_worker = simulated_worker
      deb = LOG_RANGE.map do |krw_r_value|
        delayed_estimated_benefit(base_worker, krw_r_value, LOG_DELAY)
      end
      taint_best_benefit(deb)
      Happy.logstash.with(type: 'estimated_benefit')
        .at_once(time: simulated_worker.time - LOG_DELAY)
        .stash_all(deb)
    end
  end
end
