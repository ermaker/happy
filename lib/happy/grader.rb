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

    LOW_FILTER = lambda do |_, _, values|
      values[0] > 0 &&
        values[1] > 0 &&
        values[2] >= -0.001 &&
        values[3] >= -0.005 &&
        values[4] >= -0.01
    end

    DEFAULT_FILTER = lambda do |_, _, values|
      values[0] >= 0.005 &&
        values[1] >= 0.005 &&
        values[2] >= -0.001 &&
        values[3] >= -0.005 &&
        values[4] >= -0.01
    end

    CURRENT_FILTER = LOW_FILTER

    def reference_values(path, multiplier)
      now = Time.now
      base_amount = 100000
      (base_amount..multiplier * base_amount).step(base_amount).map do |amount|
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
      end
    end

    def timing?(path)
      reference_values(path, 5)
        .select(&CURRENT_FILTER).max
    end

    def peak?(path)
      reference_values(path, 5)
        .select do |_, _, values|
          values[0] >= 0.01 &&
            values[1] >= 0.01
        end.max
    end

    def steady01?(path)
      reference_values(path, 1)
        .select do |_, _, values|
          values[0] >= 0.001 &&
            values[1] >= 0.001 &&
            values[2] >= 0.001 &&
            values[3] >= 0.001 &&
            values[4] >= 0.001
        end.max
    end

    def steady02?(path)
      reference_values(path, 1)
        .select do |_, _, values|
          values[0] >= 0.002 &&
            values[1] >= 0.002 &&
            values[2] >= 0.002 &&
            values[3] >= 0.002
        end.max
    end

    def steady03?(path)
      reference_values(path, 1)
        .select do |_, _, values|
          values[0] >= 0.003 &&
            values[1] >= 0.003 &&
            values[2] >= 0.003
        end.max
    end

    def steady05?(path)
      reference_values(path, 2)
        .select do |_, _, values|
          values[0] >= 0.005 &&
            values[1] >= 0.005
        end.max
    end

    def steady08?(path)
      reference_values(path, 2)
        .select do |_, _, values|
          values[0] >= 0.008 &&
            values[1] >= 0.008
        end.max
    end
  end
end
