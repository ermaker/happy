module Happy
  class Tester
    def test
      worker = Worker.new
      worker.extend(XCoin::Information)
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)
      worker.extend(Worker::Exchange)
      worker.extend(XCoin::Exchange)

      worker.time = Time.now - 30 * 60

      worker.xcoin_ensure_login
      result = worker.exchange(
        Amount.new('3000', 'KRW_X'),
        Currency::BTC_X
        )
      puts result
      worker.exchange(
        result[Currency::BTC_X],
        Currency::BTC_B2R
      )
    end
  end
end
