require 'bigdecimal'

class Object
  def to_jsonify
    self
  end
end

class Array
  def to_jsonify
    map(&:to_jsonify)
  end
end

class Hash
  def to_jsonify
    Hash[map { |k, v| [k, v.to_jsonify] }]
  end
end

class Time
  def to_jsonify
    utc.strftime('%FT%T.%L%z')
  end
end

class BigDecimal
  def to_jsonify
    { 'value' => to_f, 'raw' => to_s }
  end
end
