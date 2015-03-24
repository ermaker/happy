module Happy
  class Tester
    def test_z
      worker = Worker.new
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)

      query = Util::Query.new
      query[:index] = 'logstash-balances-*'
      query[:type] = 'balances'
      query[:body][:size] = 0
      query[:body][:aggs] = {
        '1': {
          'min': {
            'field': '@timestamp',
            'script_file': 'test'
          }
        }
      }
      # query.sort('@timestamp': { order: 'desc' })

      require 'pp'
      pp worker.es_client.search(query)
    end

    def min_of_avg(from, to, base)
      worker = Worker.new
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)

      query = Util::Query.new
      query[:index] = 'logstash-estimated_benefit-*'
      query[:type] = 'estimated_benefit'
      query.match(algo: 'simple')
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

    def delayed_estimated_benefit(time, base)
      worker = Worker.new
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)

      query = Util::Query.new
      query[:index] = 'logstash-estimated_benefit-*'
      query[:type] = 'estimated_benefit'
      query.match(algo: 'delayed')
      query.match(base: base)
      query.range('@timestamp': { lte: time }.to_jsonify)
      query[:body][:size] = 1
      query.sort('@timestamp': { order: 'desc' })
      worker.es_client.search(query)['hits']['hits'].first['_source']['benefit']
    end

    def test_x
      require 'pp'
      base_amount = 100000
      base_time = (Time.now - 60 * 60).to_i
      (base_time - 60 * 60..base_time).step(60).map do |now|
        now = Time.at(now)
        [
          min_of_avg(now - 10 * 60, now, base_amount) / base_amount * 100,
          min_of_avg(now - 30 * 60, now, base_amount) / base_amount * 100,
          min_of_avg(now - 50 * 60, now, base_amount) / base_amount * 100,
          min_of_avg(now - 70 * 60, now, base_amount) / base_amount * 100,
          delayed_estimated_benefit(now, base_amount) / base_amount * 100
        ].tap { |item| pp item }
      end
    end

    def test
      Happy.logger.level = Logger::INFO

      worker = Worker.new
      worker.extend(XCoin::Information)
      worker.extend(XRP::Information)
      worker.extend(BitStamp::Information)
      worker.extend(PaxMoneta::Information)
      worker.extend(Worker::Balance)
      # worker.extend(Logged::Balance) # TODO
      # worker.extend(XCoin::Balance)
      # worker.extend(BitStamp::Balance)
      # worker.extend(XRP::Balance)
      worker.extend(Simulator::Balance)
      worker.extend(Worker::Market)
      # worker.extend(Logged::Market)
      # worker.extend(XCoin::Market)
      worker.extend(XRP::Market)
      worker.extend(Worker::Exchange)
      worker.extend(Real::SimulatedExchange)
      # worker.extend(XCoin::Exchange)
      worker.extend(XCoin::SimulatedExchange)
      worker.extend(B2R::SimulatedExchange)
      # worker.extend(BitStamp::Exchange)
      worker.extend(BitStamp::SimulatedExchange)
      # worker.extend(XRP::Exchange)
      worker.extend(XRP::SimulatedExchange)
      # worker.extend(PaxMoneta::Exchange)
      worker.extend(PaxMoneta::SimulatedExchange)

      initial_balance = Amount.new('285500', 'KRW_R')
      worker.initial_balance = initial_balance
      # worker.local_balances.apply(-initial_balance)
      # worker.local_balances.apply(initial_balance['value'].currency('KRW_P') * '0.995')
      # worker.local_balances.apply('0.001'.currency('BTC_BS'))
      # worker.local_balances.apply('0.30738461'.currency('BTC_P'))
      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)
      Happy.logger.info { "local_balances: #{worker.local_balances}" }
      [
        Currency::KRW_R,
        Currency::KRW_P,
        Currency::XRP,
        Currency::BTC_BSR
        # Currency::KRW_R,
        # Currency::KRW_X,
        # Currency::KRW_X,
        # Currency::BTC_X,
        # Currency::BTC_BS,
        # Currency::BTC_BS,
        # Currency::BTC_BSR,
        # Currency::BTC_BSR,
        # Currency::XRP,
        # Currency::KRW_P,
        # Currency::KRW_R
      ].each_cons(2) do |base,counter|
        result = worker.exchange(worker.local_balances[base], counter)
        Happy.logger.debug { "result: #{result}" }
        Happy.logger.debug { "local_balances: #{worker.local_balances}" }
      end
      Happy.logger.info { "local_balances: #{worker.local_balances}" }
      Happy.logger.info { "benefit: #{worker.benefit}" }
      percent = ((worker.benefit/worker.initial_balance)['value'] * 100)
        .round(2).to_s('F')
      percent = "#{percent}%"
      Happy.logger.info do
        "#{worker.benefit.to_human(round: 2)}(#{percent}) with #{worker.initial_balance.to_human}"
      end
    end
  end
end
