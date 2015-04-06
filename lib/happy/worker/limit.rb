module Happy
  class Worker
    class Limit < Base
      def perform_(job, phase, path)
        method(phase).call(job, path)
      end

      def mshard_id(path)
        "limit_#{path}"
      end

      def limit(job, path)
        now = MShard::MShard.new.get_safe(mshard_id(path)).to_i
        value = job.balances[Currency::KRW_R]['value'].to_i
        value = now if value > now

        job.initial_balances =
          job.balances[Currency::KRW_R].tap do |krw_r|
            krw_r['value'] = value
          end
      end

      def update(job, path)
        now = MShard::MShard.new.get_safe(mshard_id(path)).to_i
        now -= job.initial_balances[Currency::KRW_R]['value'].to_i
        MShard::MShard.new.set_safe(
          id: mshard_id(path),
          contents: now
        )
      end
    end
  end
end
