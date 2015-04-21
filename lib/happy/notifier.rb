module Happy
  class Notifier
    def notify_if(path)
      best = yield(path)
      return unless best
      estimated_benefit, base, values = best
      krw_r_to_human = "#{base / 100000}-KRW"
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_status',
        type: 'note',
        title: "T]#{krw_r_to_human}(#{(values[0]*100).round(2)}%)",
        body: "#{path}\n#{estimated_benefit.round(2)}\n#{values}"
      )
    end

    def notify_if_timing(path)
      notify_if(path, &Grader.new.method(:timing?))
    end

    def notify_if_peak(path)
      notify_if(path, &Grader.new.method(:peak?))
    end

    def notify_if_steady(path)
      notify_if(path, &Grader.new.method(:steady08?))
      notify_if(path, &Grader.new.method(:steady05?))
      notify_if(path, &Grader.new.method(:steady03?))
      notify_if(path, &Grader.new.method(:steady02?))
      notify_if(path, &Grader.new.method(:steady01?))
    end

    def main
      notify_if_peak('KRW/PAX/XRP/BS/XCOIN/KRW')
      notify_if_steady('KRW/PAX/XRP/BS/XCOIN/KRW')
      notify_if_timing('KRW/XCOIN/B2R/XRP/PAX/KRW')
      notify_if_timing('KRW/XCOIN/BS/XRP/PAX/KRW')
    end
  end
end
