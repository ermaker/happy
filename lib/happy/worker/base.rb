module Happy
  class Worker
    class Base
      include Sidekiq::Worker
      sidekiq_options retry: false

      attr_accessor :stop_object

      def stop
        throw(@stop_object)
      end

      def perform(job, *args)
        catch do |stop_object|
          @stop_object = stop_object
          job = Job.from_jsonify(job)
          args = args.to_objectify
          perform_(job, *args)
          job.work
        end
      end

      class Exchange < Base
        def perform_(job, base, counter)
          Happy.logger.debug { "before balance: #{job.local['balances']}" }
          worker(job) do |w|
            unless base.currency == Currency::BTC_X && counter.currency == Currency::KRW_X
              w.wait(w.local_balances[base])
            end
            w.exchange(w.local_balances[base], counter)
          end
          Happy.logger.debug { "after balance: #{job.local['balances']}" }
        end
      end
    end
  end
end
