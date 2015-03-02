require 'thor'
require 'happy'

module Happy
  class CLI < Thor
    desc 'xrp', 'XRP'
    def xrp
      Collector.new.log_market_xrp
    end
  end
end
