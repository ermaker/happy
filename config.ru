#\ -p 9494 -o 0.0.0.0 -E production -P tmp/pids/web.pid -D

require 'dotenv'
Dotenv.load

require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { size: 1 }
end

require 'sidekiq/web'
use Rack::Auth::Basic do |user, pass|
  user == ENV['SIDEKIQ_USERNAME'] &&
    pass == ENV['SIDEKIQ_PASSWORD']
end
run Sidekiq::Web
