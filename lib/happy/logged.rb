require 'happy'
require 'elasticsearch'

module Happy
  module Logged
    module Market
      attr_accessor :es_client

      def self.extended(mod)
        mod.es_client = Elasticsearch::Client.new url: ENV['ES_URI']
        [
          [Happy::Currency::KRW_X, Happy::Currency::BTC_X],
          [Happy::Currency::BTC_P, Happy::Currency::XRP],
          [Happy::Currency::XRP, Happy::Currency::KRW_P]
        ].each do |base,counter|
          mod.proc_market[[base, counter]] = mod.method(:market_logged)
        end
      end

      attr_reader :time

      def time=(time)
        @time = time.utc
      end

      def market_logged_round(time)
        Time.utc(
          time.year, time.month, time.day,
          time.hour, time.min)
      end

      def market_logged_lower
        market_logged_round(time - 30 * 60)
      end

      def market_logged_upper
        market_logged_round(time + 60)
      end

      def market_logged_range
        # { gt: market_logged_lower, lte: market_logged_upper }.to_jsonify
        { lte: market_logged_upper }.to_jsonify
          .tap { |range| Happy.logger.debug { "Time range: #{range}" } }
      end

      def market_logged_base_query(base, counter)
        Happy::Util::Query.new.tap do |query|
          query[:index] = 'logstash-market_prices-*'
          query[:type] = 'market_prices'
          query.match('taker_pays_funded.currency': base['currency'])
          query.match('taker_pays_funded.counterparty': base['counterparty']) unless base['counterparty'].empty?
          query.match('taker_gets_funded.currency': counter['currency'])
          query.match('taker_gets_funded.counterparty': counter['counterparty']) unless counter['counterparty'].empty?
        end
      end

      def market_logged_last_status(base_query)
        bulk_query = base_query.deep_dup
        bulk_query.exists('price_count')
        bulk_query.range('@timestamp': market_logged_range)
        bulk_query[:body][:size] = 1
        bulk_query.sort('@timestamp': { order: 'desc' })
        loop do
          bulk = es_client.search(bulk_query)['hits']['hits'].first
          return bulk['_source'] unless bulk.nil?
          Happy.logger.debug 'last_status.sleep ...'
          sleep 0.3
        end
      end

      def market_logged_hits(base_query, last_status)
        hits_query = base_query.deep_dup
        hits_query.match('@timestamp': last_status['@timestamp'])
        hits_query[:body][:size] = last_status['price_count']
        hits_query.sort('price.value.value': { order: 'asc' })
        loop do
          hits_ = es_client.search(hits_query)['hits']
          return hits_['hits'] if hits_['total'] == last_status['price_count']
          Happy.logger.debug 'hits.sleep ...'
          sleep 0.3
        end
      end

      def market_logged(base, counter)
        base_query = market_logged_base_query(base, counter)
        last_status = market_logged_last_status(base_query)
        market_logged_hits(base_query, last_status).map do |hit|
          hit['_source']
        end.to_objectify
      end
    end
  end
end
