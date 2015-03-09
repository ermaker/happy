class Object
  def to_objectify
    self
  end
end

class Hash
  AMOUNT_KEYS = %w(value currency counterparty)
  CURRENCY_KEYS = %w(currency counterparty)
  def to_objectify
    case
    when AMOUNT_KEYS.all? { |key| keys.include?(key) }
      Happy::Amount[self]
    when CURRENCY_KEYS.all? { |key| keys.include?(key) }
      Happy::Currency[self]
    else
      Hash[map { |k, v| [k, v.to_objectify] }]
    end
  end
end

class Array
  def to_objectify
    map(&:to_objectify)
  end
end
