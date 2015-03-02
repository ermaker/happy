require 'happy/version'

require 'ext/jsonify'
require 'ext/objectify'
require 'ext/hash_filter'
require 'happy/util/logstash'
require 'logger'
require 'dotenv'
Dotenv.load
require 'mshard/mshard'

module Happy
  autoload :Currency, 'happy/currency'
  autoload :Amount, 'happy/amount'
  autoload :AmountHash, 'happy/amount_hash'
  autoload :XRP, 'happy/xrp'
  autoload :Collector, 'happy/collector'

  module_function

  def logger
    @logger ||= Logger.new($stderr)
  end

  def logstash
    @logstash ||= Util::Logstash.new(ENV['LS_IP'], ENV['LS_PORT'])
  end
end
