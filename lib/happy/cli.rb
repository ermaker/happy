require 'thor'
require 'happy'
require 'happy/tester'

module Happy
  class CLI < Thor
    desc 'log_market', 'Log Market'
    def log_market
      Collector.new.log_market
    end

    desc 'test', 'Test'
    def test
      Tester.new.test
    end
  end
end
