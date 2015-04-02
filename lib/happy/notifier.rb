module Happy
  class Notifier
    def min_of_avg(from, to, base, path)
      worker = Worker.new
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)

      query = Util::Query.new
      query[:index] = 'logstash-estimated_benefit-*'
      query[:type] = 'estimated_benefit'
      query.match(algo: 'simple')
      query.match('path.raw': path)
      query.match(base: base)
      query.range('@timestamp': { gt: from, lte: to }.to_jsonify)
      query[:body][:size] = 0
      query[:body][:aggs] = {
        benefit: {
          date_histogram: {
            field: '@timestamp',
            interval: '5m'
          },
          aggs: {
            benefit: {
              avg: {
                field: 'benefit'
              }
            }
          }
        }
      }
      worker.es_client.search(query)['aggregations']['benefit']['buckets']
        .map { |bucket| bucket['benefit']['value'] }.min
    end

    def best(path)
      now = Time.now
      base_amount = 100000

      (base_amount..5 * base_amount).step(base_amount).select do |amount|
        min_of_avg(now - 10 * 60, now, amount, path) / amount >= 0
      end.max
    end

    def notify_(path)
      value = best(path)
      return unless value
      krw_r_value = value
      krw_r = Amount.new(krw_r_value, 'KRW_R')
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_status',
        type: 'note',
        title: "Positive",
        body: "path: #{path}\nbase: #{krw_r.to_human}"
      )
    end

    def timing?(path)
      now = Time.now
      base_amount = 100000
      (base_amount..5 * base_amount).step(base_amount).map do |amount|
        [
          min_of_avg(now - 10 * 60, now, amount, path),
          amount,
          [
            min_of_avg(now - 10 * 60, now, amount, path) / amount,
            min_of_avg(now - 30 * 60, now, amount, path) / amount,
            min_of_avg(now - 50 * 60, now, amount, path) / amount,
            min_of_avg(now - 70 * 60, now, amount, path) / amount
          ]
        ]
      end.select do |_,_,values|
        values[0] >= 0.005 &&
          values[1] >= -0.001 &&
          values[2] >= -0.005 &&
          values[3] >= -0.01
      end.max
    end

    def notify(path)
      best = timing?(path)
      return unless best
      estimated_benefit, base, values = best
      krw_r = base.currency('KRW_R')
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_status',
        type: 'note',
        title: "Timing: #{estimated_benefit.round(2)}KRW(#{(values[0]*100).round(2)}%)",
        body: "path: #{path}\nbase: #{krw_r.to_human}\n#{values}"
      )
    end

    def simulate(path)
      best = timing?(path)
      return unless best
      _, base, _ = best
      krw_r = base.currency('KRW_R')
      run(krw_r)
    end

    def main
      notify('KRW/PAX/XRP/BS/XCOIN/KRW')
      notify('KRW/XCOIN/BS/XRP/PAX/KRW')
      notify('KRW/XCOIN/B2R/XRP/PAX/KRW')
    end
  end
end
