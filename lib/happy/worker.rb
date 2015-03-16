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
        balances =
          proc_balance.select do |currency,_|
            currencies.include?(currency)
          end.values.uniq.map(&:call)
        AmountHash.new.apply(balances)
      end

      def wait(amount, time: nil)
        currency = amount.currency
        if time.nil?
          method(:loop)
        else
          (time/5).method(:times)
        end.call do
          begin
            return true if amount <= balance(currency)[currency]
          rescue
          end
          sleep 5
        end
        false
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

      def value_shift(amount, counter)
        asks = market(amount.currency, counter)
        rest_amount = amount
        price = counter.with('0')
        ask_idx = -1
        loop do
          ask = asks[ask_idx += 1]
          price_ = ask['taker_gets_funded']
          pay = ask['taker_pays_funded']
          if rest_amount >= pay
            rest_amount -= pay
            price += price_
          else
            price += price_ * rest_amount / pay
            break
          end
        end
        price
      end
    end

    module Exchange
      attr_reader :initial_balance
      attr_accessor :local_balances
      attr_accessor :proc_exchange

      def self.extended(mod)
        mod.local_balances = AmountHash.new
        mod.initial_balance = Amount.new('0', 'KRW_R')
        mod.proc_exchange = Hash.new(mod.method(:exchange_default))
      end

      def initial_balance=(amount)
        local_balances.apply(amount)
        @initial_balance = amount
      end

      def benefit
        local_balances[initial_balance.currency] - initial_balance
      end

      def exchange_default(base, counter)
        fail "No exchange defined for #{base} -> #{counter}"
      end

      def exchange(amount, counter)
        Happy.logger.info { "Exchange from #{amount} to #{counter}" }
        proc_exchange[[amount.currency, counter]]
          .call(amount, counter).tap do |result|
          local_balances.apply(result)
        end
      end
    end
  end
end
