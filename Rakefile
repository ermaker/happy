require 'dotenv'
Dotenv.load
require 'bundler/gem_tasks'

namespace :web do
  task :up do
    system('rackup')
  end

  task :down do
    system('kill `cat tmp/pids/web.pid`')
  end

  task re: [:down, :up]
end

QUEUE_LIST = [
  :krw_r,
  :krw_x,
  :btc_x,
  :btc_bs,
  :btc_bsr,
  :btc_b2r,
  :btc_p,
  :xrp,
  :krw_p,
  :simulate
]

namespace :worker do
  task :up, :name do |_,args|
    Array(args.name || QUEUE_LIST).each do |name|
      system("sidekiq -C config/worker.yml -P tmp/pids/worker_#{name}.pid -q #{name} -L #{ENV['WORKER_LOGFILE']}")
    end
  end

  task :down, :name do |_,args|
    Array(args.name || QUEUE_LIST).each do |name|
      system("kill `cat tmp/pids/worker_#{name}.pid`")
    end
  end

  task :re, [:name] => [:down, :up]
end
