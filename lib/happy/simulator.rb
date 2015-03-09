module Happy
  module Simulator
    module Balance
      attr_accessor :simulated_balance

      def self.extended(mod)
        mod.simulated_balance = AmountHash.new
      end

      def balance(*_currencies)
        simulated_balance
      end
    end
  end
end
