module Happy
  module Real
    module SimulatedExchange
      def self.extended(mod)
        [
          [Currency::KRW_R, Currency::KRW_X],
          [Currency::KRW_R, Currency::KRW_P]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:move_real_simulated)
        end
      end

      ANTI_FEE_RATIO = Hash.new(BigDecimal.new('1'))
      ANTI_FEE_RATIO[[Currency::KRW_R, Currency::KRW_P]] =
        Amount::PAXMONETA_ANTI_FEE_RATIO

      def move_real_simulated(amount, counter)
        anti_fee_ratio = ANTI_FEE_RATIO[[amount.currency, counter.currency]]
        AmountHash.new.apply(
          -amount,
          counter.with(amount) * anti_fee_ratio
        )
      end
    end
  end
end
