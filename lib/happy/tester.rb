module Happy
  class Tester
    def test
      worker = Worker.new
      # worker.extend(XCoin::Information)
      worker.extend(XRP::Information)
      worker.extend(PaxMoneta::Information)
      #worker.extend(Worker::Market)
      #worker.extend(Logged::Market)
      worker.extend(Worker::Exchange)
      # worker.extend(XCoin::Exchange)
      #worker.extend(B2R::Exchange)
      worker.extend(XRP::Exchange)
      worker.extend(PaxMoneta::Exchange)

      worker.time = Time.now - 30 * 60

      # worker.xcoin_ensure_login
      # result = worker.exchange(
      #   Amount.new('3500', 'KRW_X'),
      #   Currency::BTC_X
      #   )
      # puts result
      # result = worker.exchange(
      #   result[Currency::BTC_X],
      #   Currency::BTC_B2R
      # )
      # puts result
      # result = worker.exchange(
      #   result[Currency::BTC_B2R],
      #   Currency::BTC_P
      # )
      # puts result
      # # result = worker.exchange(
      # #   Amount.new('0.01', 'BTC_B2R'),
      # #   Currency::BTC_P
      # # )
      # # puts result
      # result = worker.exchange(
      #   result[Currency::BTC_P],
      #   Currency::XRP
      # )
      # puts result
      # result = worker.exchange(
      #   result[Currency::XRP],
      #   Currency::KRW_P
      # )
      # puts result
      result = worker.exchange(
        Amount.new('100503', 'KRW_P'),
        Currency::KRW_R
      )
      puts result
    end
  end
end
