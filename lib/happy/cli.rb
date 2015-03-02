require 'thor'
require 'happy'

module Happy
  class CLI < Thor
    desc 'xrp', 'XRP'
    def xrp
      Collector.new.log_market_xrp
    end

    desc 'xcoin', 'XCoin'
    def xcoin
      Collector.new.log_market_xcoin
    end
  end
end
