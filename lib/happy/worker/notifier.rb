module Happy
  class Worker
    class Notifier < Base
      def perform_(job, phase)
        method(phase).call(job)
      end

      def start(job)
        initial = job.initial_balances
        krw_r = initial[Currency::KRW_R]
        path = job.path
        Happy.logger.info { "Order Start: #{krw_r} (#{path})" }
        MShard::MShard.new.set_safe(
          pushbullet: true,
          channel_tag: 'morder_process',
          type: 'note',
          title: "Got Order: #{krw_r.to_human}",
          body: "path: #{path}\ninitial: #{initial}"
        )
      end

      def finish(job)
        initial = job.initial_balances
        krw_r = initial[Currency::KRW_R]
        path = job.path
        balances = job.balances
        benefit = balances[Currency::KRW_R] - krw_r
        percent = (benefit / krw_r * 100)['value']
          .round(2).to_s('F') + '%'
        time = "#{((Time.now - job.start_time) / 60).round(2)}m"
        Happy.logger.info { "benefit: #{benefit} (#{percent}, #{path}, #{time})" }
        MShard::MShard.new.set_safe(
          pushbullet: true,
          channel_tag: 'morder_process',
          type: 'note',
          title: "#{benefit.to_human(round: 2)}(#{percent})",
          body: "initial: #{krw_r.to_human}\npath: #{path}\ntime: #{time}\nstatus: #{balances}"
        )
      end
    end
  end
end
