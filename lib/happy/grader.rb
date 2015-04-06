module Happy
  class Grader
    def query_with(base, path)
      Util::Query.new.tap do |query|
        query[:index] = 'logstash-estimated_benefit-*'
        query[:type] = 'estimated_benefit'
        query.match(algo: 'simple')
        query.match('path.raw': path)
        query.match(base: base)
      end
    end

    def seb(base, path)
      worker = Worker.new
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)

      query = query_with(base, path)
      query[:body][:size] = 1
      query.sort('@timestamp': { order: 'desc' })
      worker.es_client.search(
        query
      )['hits']['hits'][0]['_source']
    end

    def min_of_avg(from, to, base, path)
      worker = Worker.new
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)

      query = query_with(base, path)
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

    def timing?(path)
      now = Time.now
      base_amount = 100000
      (base_amount..5 * base_amount).step(base_amount).map do |amount|
        seb_ = seb(amount, path)
        [
          seb_['benefit'],
          amount,
          [
            seb_['percent'] / 100,
            min_of_avg(now - 10 * 60, now, amount, path) / amount,
            min_of_avg(now - 30 * 60, now, amount, path) / amount,
            min_of_avg(now - 50 * 60, now, amount, path) / amount,
            min_of_avg(now - 70 * 60, now, amount, path) / amount
          ]
        ]
      end.select do |_,_,values|
        values[0] >= 0.005 &&
          values[1] >= 0.005 &&
          values[2] >= -0.001 &&
          values[3] >= -0.005 &&
          values[4] >= -0.01
      end.max
    end
  end
end