#\ -p 9494 -o 0.0.0.0 -E production -P tmp/pids/web.pid -D
require 'sidekiq'

Sidekiq.configure_client do |config|
  config.redis = { size: 1 }
end

require 'sidekiq/web'
run Sidekiq::Web
