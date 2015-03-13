module Happy
  module B2R
    module SimulatedExchange
      def self.extended(mod)
        [
          [Currency::BTC_B2R, Currency::BTC_P]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_b2r_simulated)
        end
      end

      def send_b2r_simulated(amount, counter)
        AmountHash.new.apply(
          -amount,
          counter.with(amount)
        )
      end
    end
  end
end
