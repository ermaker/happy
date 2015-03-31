module Happy
  class Worker
    class Base
      include Sidekiq::Worker
      sidekiq_options retry: false

      def perform(job, *args)
        job = Job.from_jsonify(job)
        args = args.to_objectify
        perform_(job, *args)
        job.work
      end

      class Exchange < Base
        def perform_(job, base, counter)
          Happy.logger.debug { "before balance: #{job.local['balances']}" }
          worker(job) do |w|
            w.wait(w.local_balances[base])
            w.exchange(w.local_balances[base], counter)
          end
          Happy.logger.debug { "after balance: #{job.local['balances']}" }
        end
      end
    end
  end
end
