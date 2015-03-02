require 'socket'
require 'json'
require 'jsonify'

class LogstashCommon
  def initialize scope = {}
    @scope = scope
  end

  def normalized_time time
    Time.new(
      time.year, time.month, time.day,
      time.hour, time.min
    )
  end

  def at_once norm: false, &blk
    time = Time.now
    time = normalized_time(time) if norm
    with('@timestamp' => time, &blk)
  end

  def with scope
    logstash_scoped = LogstashScoped.new(self, @scope.merge(scope))
    if block_given?
      yield logstash_scoped
    else
      logstash_scoped
    end
  end
end

class LogstashUDP < LogstashCommon
  def initialize host, port
    super()
    @udp = UDPSocket.new
    @udp.connect(host, port)
  end

  def stash hash = {}
    @udp.send("#{hash.to_jsonify.to_json}\n", 0)
  end
end

class LogstashScoped < LogstashCommon
  def initialize logstash, scope
    super(scope)
    @logstash = logstash
  end

  def stash hash = {}
    @logstash.stash(@scope.merge(hash))
  end
end

Logstash = LogstashUDP
