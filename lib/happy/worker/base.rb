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
    end
  end
end
