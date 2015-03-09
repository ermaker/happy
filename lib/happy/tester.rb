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
      worker.exchange(
        Amount.new('3000', 'KRW_X'),
        Currency::BTC_X
        )
    end
  end
end
