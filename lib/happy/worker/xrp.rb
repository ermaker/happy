module Happy
  class Worker
    module XRP
      class Exchange < Base::Exchange
        def worker(job)
          worker = Worker.new

          worker.extend(XCoin::Information)
          worker.extend(BitStamp::Information)
          worker.extend(Happy::XRP::Information)

          worker.extend(Worker::Balance)
          worker.extend(XCoin::Balance)
          worker.extend(BitStamp::Balance)
          worker.extend(Happy::XRP::Balance)

          worker.extend(Worker::Market)
          worker.extend(Logged::Market)

          worker.extend(Worker::Exchange)
          worker.extend(XCoin::Exchange)
          worker.extend(BitStamp::Exchange)
          worker.extend(Happy::XRP::Exchange)
          worker.extend(XRPSend::Exchange)

          worker.local_balances = job.local['balances']
          begin
            yield worker
          ensure
            worker.page.driver.quit
          end
        end
      end

      class SimulatedExchange < Base::Exchange
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
          worker.extend(Happy::XRP::SimulatedExchange)
          worker.extend(XRPSend::SimulatedExchange)

          worker.local_balances = job.local['balances']
          yield worker
        end
      end
    end
  end
end
