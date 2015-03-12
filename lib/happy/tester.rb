module Happy
  class Tester
    def test
      # Happy.logger.level = Logger::INFO

      worker = Worker.new
      worker.extend(XCoin::Information)
      worker.extend(XRP::Information)
      worker.extend(PaxMoneta::Information)
      worker.extend(Worker::Balance)
      # worker.extend(Logged::Balance) # TODO
      # worker.extend(XCoin::Balance)
      worker.extend(XRP::Balance)
      # worker.extend(Simulator::Balance)
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)
      # worker.extend(XCoin::Market)
      # worker.extend(XRP::Market)
      worker.extend(Worker::Exchange)
      worker.extend(XCoin::Exchange)
      # worker.extend(XCoin::SimulatedExchange)
      worker.extend(B2R::SimulatedExchange)
      worker.extend(XRP::Exchange)
      # worker.extend(XRP::SimulatedExchange)
      # worker.extend(PaxMoneta::Exchange)
      worker.extend(PaxMoneta::SimulatedExchange)

      worker.initial_balance = Amount.new('200000', 'KRW_R')
      worker.local_balances = AmountHash.new
      #worker.local_balances.apply(Amount.new('0.60545455', 'BTC_X'))
      worker.local_balances.apply(Amount.new('0.573971566413374', 'BTC_P'))
      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)
      Happy.logger.info { "local_balances: #{worker.local_balances}" }
      [
        # Currency::KRW_R,
        # Currency::KRW_X,
        # Currency::KRW_X,
        # Currency::BTC_X,
        # Currency::BTC_B2R,
        Currency::BTC_P,
        Currency::BTC_P,
        Currency::XRP,
        Currency::KRW_P,
        Currency::KRW_R
      ].each_cons(2) do |base,counter|
        result = worker.exchange(worker.local_balances[base], counter)
        Happy.logger.debug { "result: #{result}" }
        Happy.logger.info { "local_balances: #{worker.local_balances}" }
      end
      Happy.logger.info { "benefit: #{worker.benefit}" }
      percent = ((worker.benefit/worker.initial_balance)['value'] * 100)
        .round(2).to_s('F')
      percent = "#{percent}%"
      MShard::MShard.new.set(
        pushbullet: true,
        channel_tag: 'morder_process',
        type: 'note',
        title: "#{worker.benefit.to_human(round: 2)}(#{percent})",
        body: "#{worker.initial_balance.to_human}"
      )
    end
  end
end
