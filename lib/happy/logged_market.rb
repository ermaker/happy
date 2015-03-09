require 'elasticsearch'

module Happy
  class LoggedMarket
    def initialize
      @client = Elasticsearch::Client.new url: ENV['ES_URI']
    end

    def lower(time)
      Time.utc(
        time.year, time.month, time.day,
        time.hour, time.min)
    end

    def upper(time)
      lower(lower(time) + 60)
    end

    def range(time)
      { gt: lower(time), lte: upper(time) }.to_jsonify
        .tap { |range| Happy.logger.debug { "Time range: #{range}" } }
    end

    def base_query(base, counter)
      base_query_ = Happy::Util::Query.new
      base_query_[:index] = 'logstash-market_prices-*'
      base_query_[:type] = 'market_prices'
      # TODO: check counterparty
      base_query_.match('taker_pays_funded.currency': base['currency'])
      base_query_.match('taker_gets_funded.currency': counter['currency'])
      base_query_
    end

    def last_status(base_query, time)
      bulk_query = base_query.deep_dup
      bulk_query.exists('price_count')
      bulk_query.range('@timestamp': range(time))
      bulk_query[:body][:size] = 1
      bulk_query.sort('@timestamp': { order: 'desc' })
      loop do
        bulk = @client.search(bulk_query)['hits']['hits'].first
        return bulk['_source'] unless bulk.nil?
        Happy.logger.debug 'last_status.sleep ...'
        sleep 0.3
      end
    end

    def hits(base_query, last_status)
      hits_query = base_query.deep_dup
      hits_query.match('@timestamp': last_status['@timestamp'])
      hits_query[:body][:size] = last_status['price_count']
      hits_query.sort('price.value.value': { order: 'asc' })
      loop do
        hits_ = @client.search(hits_query)['hits']
        return hits_['hits'] if hits_['total'] == last_status['price_count']
        Happy.logger.debug 'hits.sleep ...'
        sleep 0.3
      end
    end

    def market(base, counter, time)
      time = time.utc
      base_query = base_query(base, counter)
      last_status = last_status(base_query, time)
      hits(base_query, last_status).map do |hit|
        hit['_source']
      end.to_objectify
    end
  end
end
