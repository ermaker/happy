require 'happy/version'

require 'ext/jsonify'
require 'ext/objectify'
require 'ext/hash_filter'
require 'ext/deep_dup'
require 'ext/currency'
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
  autoload :XCoin, 'happy/xcoin'
  autoload :B2R, 'happy/b2r'
  autoload :PaxMoneta, 'happy/paxmoneta'
  autoload :Worker, 'happy/worker'
  autoload :Simulator, 'happy/simulator'
  autoload :Logged, 'happy/logged'
  autoload :Collector, 'happy/collector'
  autoload :Runner, 'happy/runner'

  module Util
    autoload :Query, 'happy/util/query'
  end

  module_function

  def logger
    @logger ||= Logger.new($stderr)
  end

  def logstash
    @logstash ||= Util::Logstash.new(ENV['LS_IP'], ENV['LS_PORT'])
  end
end
