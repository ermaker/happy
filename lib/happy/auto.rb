module Happy
  class Auto
    def simulate(path)
      best = Grader.new.timing?(path)
      return unless best
      _, base, _ = best
      krw_r = base.currency('KRW_R')
      run(krw_r)
    end

    def main
      simulate('KRW/XCOIN/B2R/XRP/PAX/KRW')
      # simulate('KRW/XCOIN/BS/XRP/PAX/KRW')
    end

    def run(krw_r)
      Happy.logger.debug('SIMULATED') do
        "Order Start: #{krw_r.to_human}"
      end

      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_process',
        type: 'note',
        title: 'SIMULATE Start',
        body: "#{krw_r.to_human}"
      )

      Happy.logger.level = Logger::FATAL

      worker = Worker.new
      worker.extend(XCoin::Information)
      worker.extend(BitStamp::Information)
      worker.extend(XRP::Information)
      worker.extend(Worker::Balance)
      # worker.extend(Logged::Balance) # TODO
      # worker.extend(XCoin::Balance)
      # worker.extend(BitStamp::Balance)
      # worker.extend(XRP::Balance)
      worker.extend(Simulator::Balance)
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)
      # worker.extend(XCoin::Market)
      # worker.extend(XRP::Market)
      worker.extend(Worker::Exchange)
      worker.extend(Real::SimulatedExchange)
      # worker.extend(XCoin::Exchange)
      worker.extend(XCoin::SimulatedExchange)
      # worker.extend(B2R::SimulatedExchange)
      worker.extend(BitStamp::SimulatedExchange)
      # worker.extend(XRP::Exchange)
      worker.extend(XRP::SimulatedExchange)
      # worker.extend(XRPSend::Exchange)
      worker.extend(XRPSend::SimulatedExchange)

      worker.initial_balance = krw_r
      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)

      worker.time = Time.now
      [
        Currency::KRW_R,
        Currency::KRW_X,
        Currency::KRW_X,
        Currency::BTC_X,
        Currency::BTC_BS
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      Happy.logger.level = Logger::DEBUG
      delay = 40 * 60
      Happy.logger.debug('SIMULATED') do
        "Sleep #{delay} to simulate"
      end
      sleep(delay)
      Happy.logger.level = Logger::FATAL

      worker.time = Time.now
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

      Happy.logger.level = Logger::DEBUG

      percent = (worker.benefit/worker.initial_balance * 100)['value']
        .round(2).to_s('F') + '%'
      Happy.logger.info('SIMULATED') do
        "benefit: #{worker.benefit.to_human(round: 2)}, #{percent}"
      end
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_process',
        type: 'note',
        title: 'SIMULATE Finish',
        body: "#{worker.benefit.to_human(round: 2)}(#{percent}) #{worker.initial_balance.to_human}"
      )
    end
  end
end
