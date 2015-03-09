module Happy
  class Worker
    module Balance
      attr_accessor :proc_balance

      def self.extended(mod)
        mod.proc_balance = Hash.new(mod.method(:balance_default))
      end

      def balance_default
        {}
      end

      def balance(*currencies)
        proc_balance.select do |currency,_|
          currencies.include?(currency)
        end.values.uniq.map(&:call)
          .reduce(AmountHash.new, :merge)
      end
    end

    module Market
      attr_accessor :proc_market

      def self.extended(mod)
        mod.proc_market = Hash.new(mod.method(:market_default))
      end

      def market_default(base, counter)
        fail "No market defined for #{base} -> #{counter}"
      end

      def market(base, counter)
        proc_market[[base, counter]].call(base, counter)
      end
    end

    module Exchange
      attr_accessor :proc_exchange

      def self.extended(mod)
        mod.proc_exchange = Hash.new(mod.method(:exchange_default))
      end

      def exchange_default(base, counter)
        fail "No exchange defined for #{base} -> #{counter}"
      end

      def exchange(amount, counter)
        proc_exchange[[amount.currency, counter]].call(amount, counter)
      end
    end
  end
end
