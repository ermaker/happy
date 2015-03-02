require 'happy/amount'

module Happy
  class AmountHash < Hash
    def initialize
      super do |hash, key|
        hash[key] = Amount.new('0', key)
      end
    end

    def apply(amount)
      currency = amount.currency
      self[currency] += amount
      delete(currency) if self[currency]['value'] == BigDecimal.new('0')
    end

    def apply_all(amount_hash)
      amount_hash.values.each { |amount| apply(amount) }
    end

    def to_s
      values.map(&:to_s).to_s
    end
  end
end
