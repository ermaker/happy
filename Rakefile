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

namespace :worker do
  task :up, :name do |_,args|
    system("sidekiq -C config/#{args.name}.yml")
  end

  task :down, :name do |_,args|
    system("kill `cat tmp/pids/#{args.name}.pid`")
  end

  task :re, [:name] => [:down, :up]
end
