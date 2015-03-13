require 'happy/amount'

module Happy
  class AmountHash < Hash
    def initialize
      super do |hash, key|
        hash[key] = Amount.new('0', key)
      end
    end

    def map_amount obj
      case obj
      when Amount
        [obj]
      when Enumerable
        obj.flat_map { |item| map_amount(item) }
      else
        []
      end
    end

    BIG_ZERO = BigDecimal.new('0')

    def apply(*amount_list)
      map_amount(amount_list.to_objectify).each do |amount|
        self[amount.currency] += amount
      end
      reject! { |_,amount| amount['value'] == BIG_ZERO }
      self
    end

    alias_method :apply_all, :apply

    def to_s
      values.map(&:to_s).to_s
    end
  end
end
