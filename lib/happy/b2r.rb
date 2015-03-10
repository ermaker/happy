module Happy
  module B2R
    module SimulatedExchange
      def self.extended(mod)
        [
          [Happy::Currency::BTC_B2R, Happy::Currency::BTC_P]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_b2r_simulated)
        end
      end

      def send_b2r_simulated(amount, counter)
        AmountHash.new.tap do |ah|
          ah.apply(-amount)
          ah.apply(Amount.new(amount['value'], counter))
        end
      end
    end
  end
end
