require 'socket'
require 'json'

module Happy
  module Util
    class LogstashCommon
      def initialize(scope = {})
        @scope = scope
      end

      def normalized_time(time)
        Time.new(
          time.year, time.month, time.day,
          time.hour, time.min
        )
      end

      def at_once(norm: false, time: time, &blk)
        time ||= Time.now
        time = normalized_time(time) if norm
        with('@timestamp' => time, &blk)
      end

      def with(scope)
        logstash_scoped = LogstashScoped.new(self, @scope.merge(scope))
        if block_given?
          yield logstash_scoped
        else
          logstash_scoped
        end
      end
    end

    class LogstashUDP < LogstashCommon
      def initialize(host, port)
        super()
        @udp = UDPSocket.new
        @udp.connect(host, port)
      end

      def stash(hash = {})
        @udp.send("#{hash.to_jsonify.to_json}\n", 0)
      end

      def stash_all(list = [])
        log = list.map { |hash| "#{hash.to_jsonify.to_json}\n" }.join
        @udp.send(log, 0)
      end
    end

    class LogstashTCP < LogstashCommon
      def initialize(host, port)
        super()
        @host = host
        @port = port
      end

      def stash(hash = {})
        tcp = TCPSocket.new @host, @port
        begin
          tcp.send("#{hash.to_jsonify.to_json}\n", 0)
        ensure
          tcp.close
        end
      end

      def stash_all(list = [])
        log = list.map { |hash| "#{hash.to_jsonify.to_json}\n" }.join
        tcp = TCPSocket.new @host, @port
        begin
          tcp.send(log, 0)
        ensure
          tcp.close
        end
      end
    end

    class LogstashScoped < LogstashCommon
      def initialize(logstash, scope)
        super(scope)
        @logstash = logstash
      end

      def stash(hash = {})
        @logstash.stash(@scope.merge(hash))
      end

      def stash_all(list = [])
        @logstash.stash_all(list.map { |hash| @scope.merge(hash) })
      end
    end

    Logstash = LogstashTCP
  end
end
