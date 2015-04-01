module Happy
  class Worker
    class ExchangeWorker < Base::Exchange
      def worker(job)
        worker = Worker.new

        worker.extend(XCoin::Information)
        worker.extend(BitStamp::Information)
        worker.extend(XRP::Information)

        worker.extend(Worker::Balance)
        worker.extend(XCoin::Balance)
        worker.extend(BitStamp::Balance)
        worker.extend(XRP::Balance)

        worker.extend(Worker::Market)
        worker.extend(Logged::Market)

        worker.extend(Worker::Exchange)
        worker.extend(XCoin::Exchange)
        worker.extend(BitStamp::Exchange)
        worker.extend(XRP::Exchange)
        worker.extend(XRPSend::Exchange)

        worker.local_balances = job.balances
        begin
          yield worker
        ensure
          worker.xcoin_session.driver.quit
        end
      end

      class Simulated < Base::Exchange
        def worker(job)
          worker = Worker.new

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

          worker.local_balances = job.balances
          yield worker
        end
      end
    end
  end
end
