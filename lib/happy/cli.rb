require 'thor'
require 'happy'
require 'happy/tester'

module Happy
  class CLI < Thor
    desc 'log_market', 'Log Market'
    def log_market
      Collector.new.log_market
    end

    desc 'log_balances', 'Log Balances'
    def log_balances
      Collector.new.log_balances
    end

    desc 'test', 'Test'
    def test
      Tester.new.test
    end

    desc 'order', 'Order'
    def order
      Runner.new.main
    end

    desc 'auto', 'Auto'
    def auto
      Auto.new.main
    end
  end
end
