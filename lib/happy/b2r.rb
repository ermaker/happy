module Happy
  module B2R
    module Exchange
      def self.extended(mod)
        [
          [Happy::Currency::BTC_B2R, Happy::Currency::BTC_P]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_b2r)
        end
      end

      def send_b2r(amount, counter)
        AmountHash.new.tap do |ah|
          ah.apply(-amount)
          ah.apply(
            Amount.new(amount['value'], counter) -
            Amount.new(Amount::BTC_FEE, counter))
        end
      end
    end
  end
end
