module Happy
  class Tester
    def test
      worker = Worker.new
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)

      base = Currency::KRW_X
      counter = Currency::BTC_X

      query = Util::Query.new
      query[:index] = 'logstash-market_prices-*'
      query[:type] = 'market_prices'
      query.match('taker_pays_funded.currency': base['currency'])
      query.match('taker_pays_funded.counterparty': base['counterparty']) unless base['counterparty'].empty?
      query.match('taker_gets_funded.currency': counter['currency'])
      query.match('taker_gets_funded.counterparty': counter['counterparty']) unless counter['counterparty'].empty?

      query.range('@timestamp': { gt: Time.now - 5 * 60, lte: Time.now + 5 * 60 }.to_jsonify)
      query[:body][:size] = 0
      query[:body][:aggs] = {
        a: {
          date_histogram: {
            field: '@timestamp',
            interval: '3m'
          },
          aggs: {
            x: {
              avg: {
                field: 'base_price.value'
              },
              aggs: {
                b: {
                  terms: {
                    field: '@timestamp'
                  },
                  aggs: {
                    base_price: {
                      min: {
                        field: 'price.value.value'
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      require 'pp'
      pp worker.es_client.search(query)
    end

    def test2
      # Happy.logger.level = Logger::INFO

      worker = Worker.new
      worker.extend(XCoin::Information)
      worker.extend(XRP::Information)
      worker.extend(PaxMoneta::Information)
      worker.extend(Worker::Balance)
      # worker.extend(Logged::Balance) # TODO
      worker.extend(XCoin::Balance)
      worker.extend(XRP::Balance)
      # worker.extend(Simulator::Balance)
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)
      # worker.extend(XCoin::Market)
      # worker.extend(XRP::Market)
      worker.extend(Worker::Exchange)
      worker.extend(XCoin::Exchange)
      # worker.extend(XCoin::SimulatedExchange)
      # worker.extend(B2R::SimulatedExchange)
      # worker.extend(BitStamp::Exchange) # TODO
      # worker.extend(BitStamp::SimulatedExchange) # TODO
      # worker.extend(XRP::Exchange)
      worker.extend(XRP::SimulatedExchange)
      # worker.extend(PaxMoneta::Exchange)
      worker.extend(PaxMoneta::SimulatedExchange)

      worker.initial_balance = Amount.new('200000', 'KRW_R')
      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)
      Happy.logger.info { "local_balances: #{worker.local_balances}" }
      [
        # Currency::KRW_R,
        # Currency::KRW_X,
        # Currency::KRW_X,
        # Currency::BTC_X,
        # Currency::BTC_BS,
        # Currency::BTC_BS,
        # Currency::BTC_BSR,
        Currency::BTC_BSR,
        Currency::XRP,
        Currency::KRW_P,
        Currency::KRW_R
      ].each_cons(2) do |base,counter|
        result = worker.exchange(worker.local_balances[base], counter)
        Happy.logger.debug { "result: #{result}" }
        Happy.logger.info { "local_balances: #{worker.local_balances}" }
      end
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
