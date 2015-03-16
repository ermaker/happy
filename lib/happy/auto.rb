module Happy
  class Auto
    def main
      krw_r_value = '100000'
      krw_r = Amount.new(krw_r_value, 'KRW_R')
      run(krw_r)
    end

    def run(krw_r)
      Happy.logger.level = Logger::FATAL

      worker = Worker.new
      worker.extend(XCoin::Information)
      worker.extend(XRP::Information)
      worker.extend(PaxMoneta::Information)
      worker.extend(Worker::Balance)
      # worker.extend(Logged::Balance) # TODO
      # worker.extend(XCoin::Balance)
      # worker.extend(XRP::Balance)
      worker.extend(Simulator::Balance)
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)
      # worker.extend(XCoin::Market)
      # worker.extend(XRP::Market)
      worker.extend(Worker::Exchange)
      # worker.extend(XCoin::Exchange)
      worker.extend(XCoin::SimulatedExchange)
      worker.extend(B2R::SimulatedExchange)
      # worker.extend(XRP::Exchange)
      worker.extend(XRP::SimulatedExchange)
      # worker.extend(PaxMoneta::Exchange)
      worker.extend(PaxMoneta::SimulatedExchange)

      worker.initial_balance = krw_r
      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)

      worker.time = Time.now
      [
        Currency::KRW_R,
        Currency::KRW_X,
        Currency::KRW_X,
        Currency::BTC_X,
        Currency::BTC_B2R
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      Happy.logger.level = Logger::DEBUG
      delay = 1 * 60 * 60 + 10 * 60
      Happy.logger.debug('SIMULATED') do
        "Sleep #{delay} to simulate"
      end
      sleep(delay)
      Happy.logger.level = Logger::FATAL

      worker.time = Time.now
      [
        Currency::BTC_B2R,
        Currency::BTC_P,
        Currency::BTC_P,
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
      # MShard::MShard.new.set(
      #   pushbullet: true,
      #   channel_tag: 'morder_process',
      #   type: 'note',
      #   title: 'SIMULATED',
      #   body: "#{worker.benefit.to_human(round: 2)}(#{percent}) #{worker.initial_balance.to_human}"
      # )
    end
  end
end