module Happy
  class Worker
    class Volume < Base
      def perform_(job, phase, path)
        method(phase).call(job, path)
      end

      def mshard_id(path)
        "volume_#{path}"
      end

      def up(job, path)
        now = MShard::MShard.new.get_safe(mshard_id(path)).to_i
        value = job.balances[Currency::KRW_R]['value'].to_i
        if now >= value
          Happy.logger.info { "Stop: now(#{now}) > value(#{value})" }
          stop
        end

        job.initial_balances =
          job.balances[Currency::KRW_R].tap do |krw_r|
            krw_r['value'] = value - now
          end

        MShard::MShard.new.set_safe(
          id: mshard_id(path),
          contents: value
        )
      end

      def down(job, path)
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
