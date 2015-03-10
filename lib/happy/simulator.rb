module Happy
  module Simulator
    module Balance
      def self.extended(_mod)
      end

      def balance(*_currencies)
        local_balances
      end
    end
  end
end
