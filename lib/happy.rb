require 'happy/version'

require 'ext/jsonify'
require 'ext/objectify'
require 'ext/hash_filter'
require 'ext/deep_dup'
require 'ext/currency'
require 'ext/constantize'
require 'happy/util/logstash'
require 'logger'
require 'dotenv'
Dotenv.load
require 'mshard/mshard'

require 'sidekiq'
Sidekiq.configure_client do |config|
  config.redis = { size: 1 }
end

module Happy
  autoload :Currency, 'happy/currency'
  autoload :Amount, 'happy/amount'
  autoload :AmountHash, 'happy/amount_hash'
  autoload :XRP, 'happy/xrp'
  autoload :XRPSend, 'happy/xrp_send'
  autoload :XCoin, 'happy/xcoin'
  autoload :B2R, 'happy/b2r'
  autoload :BitStamp, 'happy/bitstamp'
  autoload :Real, 'happy/real'
  autoload :Simulator, 'happy/simulator'
  autoload :Logged, 'happy/logged'
  autoload :Collector, 'happy/collector'
  autoload :MailWorker, 'happy/mail_worker'
  autoload :Runner, 'happy/runner'
  autoload :OrderB2R, 'happy/order_b2r'
  autoload :Recycle, 'happy/recycle'
  autoload :Auto, 'happy/auto'
  autoload :Job, 'happy/job'
  autoload :JobBase, 'happy/job_base'

  module Util
    autoload :Query, 'happy/util/query'
  end

  # autoload :Worker, 'happy/worker'
  require 'happy/worker'
  class Worker
    autoload :Base, 'happy/worker/base'
    autoload :WorkerTest, 'happy/worker/worker_test'
    autoload :XRP, 'happy/worker/xrp'
  end

  module_function

  def logger
    @logger ||= Logger.new($stderr)
  end

  def logstash
    @logstash ||= Util::Logstash.new(ENV['LS_IP'], ENV['LS_PORT'])
  end
end
