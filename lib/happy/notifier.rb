module Happy
  class Notifier
    def notify(path)
      best = Grader.new.timing?(path)
      return unless best
      estimated_benefit, base, values = best
      krw_r_to_human = "#{base / 100000}-KRW"
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_status',
        type: 'note',
        title: "Timing: #{krw_r_to_human}(#{(values[0]*100).round(2)}%)",
        body: "#{path}\n#{estimated_benefit.round(2)}\n#{values}"
      )
    end

    def main
      notify('KRW/PAX/XRP/BS/XCOIN/KRW')
      notify('KRW/XCOIN/BS/XRP/PAX/KRW')
      notify('KRW/XCOIN/B2R/XRP/PAX/KRW')
    end
  end
end
