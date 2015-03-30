module Happy
  class Worker
    class WorkerTest < Base
      sidekiq_options queue: :test

      def perform_(_job, weight)
        Sidekiq.logger.info { 'START' }
        sleep(weight)
        Sidekiq.logger.info { 'END' }
      end
    end
  end
end
