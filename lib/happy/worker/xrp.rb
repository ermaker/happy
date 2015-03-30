module Happy
  class Worker
    module XRP
      class Base < Worker::Base
        sidekiq_options queue: :xrp

        def perform_(job, base, counter)
          w = worker(job)
          w.wait(w.local_balances[base])
          w.exchange(w.local_balances[base], counter)
          Happy.logger.debug { "balance: #{job.local['balances']}" }
        end
      end

      class Wait < Base
        def perform_(job, base, counter)
          Sidekiq.logger.info { "#{base}, #{counter}" }
          w = Worker.new
          w.extend(Happy::XRP::Information)
          w.extend(Worker::Balance)
          w.extend(Happy::XRP::Balance)
          balance = job.local['balances'][base]
          Sidekiq.logger.info { "balance: #{balance}" }
          w.wait(balance, time: 60)
          job.local['balances'][base] /= 2
        end
      end

      class Exchange < Base
        def worker(job)
          Worker.new.tap do |worker|
            worker.extend(Happy::XRP::Information)
            worker.extend(Worker::Balance)
            worker.extend(Happy::XRP::Balance)
            worker.extend(Worker::Market)
            worker.extend(Logged::Market)
            worker.extend(Worker::Exchange)
            worker.extend(Happy::XRP::Exchange)
            worker.extend(Happy::XRPSend::Exchange)
            worker.local_balances = job.local['balances']
          end
        end
      end

      class SimulatedExchange < Base
        def worker(job)
          Worker.new.tap do |worker|
            worker.extend(Worker::Balance)
            worker.extend(Simulator::Balance)
            worker.extend(Worker::Market)
            worker.extend(Logged::Market)
            worker.extend(Worker::Exchange)
            worker.extend(Happy::XRP::SimulatedExchange)
            worker.extend(Happy::XRPSend::SimulatedExchange)
            worker.local_balances = job.local['balances']
          end
        end
      end
    end
  end
end
