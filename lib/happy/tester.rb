module Happy
  class Tester
    def test
      worker = Worker.new
      worker.extend(XCoin::Information)
      worker.extend(XRP::Information)
      # worker.extend(PaxMoneta::Information)
      worker.extend(Worker::Balance)
      worker.extend(XRP::Balance)
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)
      worker.extend(Worker::Exchange)
      worker.extend(XCoin::Exchange)
      worker.extend(B2R::Exchange)
      worker.extend(XRP::Exchange)
      # worker.extend(PaxMoneta::Exchange)

      # For Logged::Market
      worker.time = Time.now

      worker.local_balances.apply(Amount.new('3500', 'KRW_X'))
      Happy.logger.debug { "local_balances: #{worker.local_balances}" }
      [
        Currency::KRW_X,
        Currency::BTC_X,
        Currency::BTC_B2R,
        Currency::BTC_P
      ].each_cons(2) do |base,counter|
        result = worker.exchange(worker.local_balances[base], counter)
        Happy.logger.debug { "result: #{result}" }
        Happy.logger.debug { "local_balances: #{worker.local_balances}" }
      end

      worker.wait(worker.local_balances[Currency::BTC_P])

      [
        Currency::BTC_P,
        Currency::XRP,
        Currency::KRW_P
      ].each_cons(2) do |base,counter|
        result = worker.exchange(worker.local_balances[base], counter)
        Happy.logger.debug { "result: #{result}" }
        Happy.logger.debug { "local_balances: #{worker.local_balances}" }
      end
    end
  end
end
