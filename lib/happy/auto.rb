module Happy
  class Auto
    def min_of_avg(from, to, base, path)
      worker = Worker.new
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)

      query = Util::Query.new
      query[:index] = 'logstash-estimated_benefit-*'
      query[:type] = 'estimated_benefit'
      query.match(algo: 'simple')
      query.match(path: path)
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

    def main
      value = best('KRW/PAX/XRP/BS/XCOIN/KRW')
      if value
        krw_r_value = value
        krw_r = Amount.new(krw_r_value, 'KRW_R')
        MShard::MShard.new.set_safe(
          pushbullet: true,
          channel_tag: 'morder_status',
          type: 'note',
          title: 'R] Checked maximum benefit',
          body: "#{krw_r.to_human}"
        )
      end

      value = best('KRW/XCOIN/BS/XRP/PAX/KRW')
      if value
        krw_r_value = value
        krw_r = Amount.new(krw_r_value, 'KRW_R')
        MShard::MShard.new.set_safe(
          pushbullet: true,
          channel_tag: 'morder_status',
          type: 'note',
          title: 'Checked maximum benefit',
          body: "#{krw_r.to_human}"
        )
      end

      now = Time.now
      base_amount = 100000
      path = 'KRW/XCOIN/BS/XRP/PAX/KRW'
      value = (base_amount..5 * base_amount).step(base_amount).select do |amount|
        min_of_avg(now - 10 * 60, now, amount, path) / amount >= 0.005 &&
          min_of_avg(now - 30 * 60, now, amount, path) / amount >= 0.001 &&
          min_of_avg(now - 50 * 60, now, amount, path) / amount >= -0.005 &&
          min_of_avg(now - 70 * 60, now, amount, path) / amount >= -0.01
      end.max
      if value
        krw_r_value = value
        krw_r = Amount.new(krw_r_value, 'KRW_R')
        run(krw_r)
      end
    end

    def run(krw_r)
      Happy.logger.debug('SIMULATED') do
        "Order Start: #{krw_r.to_human}"
      end

      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_process',
        type: 'note',
        title: 'SIMULATE Start',
        body: "#{krw_r.to_human}"
      )

      Happy.logger.level = Logger::FATAL

      worker = Worker.new
      worker.extend(XCoin::Information)
      worker.extend(BitStamp::Information)
      worker.extend(XRP::Information)
      worker.extend(Worker::Balance)
      # worker.extend(Logged::Balance) # TODO
      # worker.extend(XCoin::Balance)
      # worker.extend(BitStamp::Balance)
      # worker.extend(XRP::Balance)
      worker.extend(Simulator::Balance)
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)
      # worker.extend(XCoin::Market)
      # worker.extend(XRP::Market)
      worker.extend(Worker::Exchange)
      worker.extend(Real::SimulatedExchange)
      # worker.extend(XCoin::Exchange)
      worker.extend(XCoin::SimulatedExchange)
      # worker.extend(B2R::SimulatedExchange)
      worker.extend(BitStamp::SimulatedExchange)
      # worker.extend(XRP::Exchange)
      worker.extend(XRP::SimulatedExchange)
      # worker.extend(XRPSend::Exchange)
      worker.extend(XRPSend::SimulatedExchange)

      worker.initial_balance = krw_r
      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)

      worker.time = Time.now
      [
        Currency::KRW_R,
        Currency::KRW_X,
        Currency::KRW_X,
        Currency::BTC_X,
        Currency::BTC_BS
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      Happy.logger.level = Logger::DEBUG
      delay = 1 * 60 * 60 + 10 * 60
      Happy.logger.debug('SIMULATED') do
        "Sleep #{delay} to simulate"
      end
      sleep(delay)
      Happy.logger.level = Logger::FATAL

      worker.time = Time.now
      [
        Currency::BTC_BS,
        Currency::BTC_BS,
        Currency::BTC_BSR,
        Currency::BTC_BSR,
        Currency::XRP,
        Currency::KRW_P,
        Currency::KRW_R
      ].each_cons(2) do |base,counter|
        worker.exchange(worker.local_balances[base], counter)
      end

      Happy.logger.level = Logger::DEBUG

      percent = (worker.benefit/worker.initial_balance * 100)['value']
        .round(2).to_s('F') + '%'
      Happy.logger.info('SIMULATED') do
        "benefit: #{worker.benefit.to_human(round: 2)}, #{percent}"
      end
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_process',
        type: 'note',
        title: 'SIMULATE Finish',
        body: "#{worker.benefit.to_human(round: 2)}(#{percent}) #{worker.initial_balance.to_human}"
      )
    end
  end
end
