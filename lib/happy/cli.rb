require 'thor'
require 'happy'

module Happy
  class CLI < Thor
    desc 'log_market', 'Log Market'
    def log_market
      Collector.new.log_market
    end
  end
end
