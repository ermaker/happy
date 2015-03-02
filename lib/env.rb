require 'logstash'
require 'logger'
require 'dotenv'

Dotenv.load

require 'mshard/mshard'

$logger = Logger.new($stderr)
$logstash = Logstash.new(ENV['LS_IP'], ENV['LS_PORT'])
