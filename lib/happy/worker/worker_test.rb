module Happy
  class Worker
    class WorkerTest < Base
      sidekiq_options queue: :xrp

      def perform_(_job, weight)
        Sidekiq.logger.info { "sleep(#{weight})" }
        sleep(weight)
      end
    end
  end
end
