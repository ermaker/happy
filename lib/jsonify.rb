class Object
  def to_jsonify
    self
  end
end

class Hash
  def to_jsonify
    Hash[map { |k,v| [k, v.to_jsonify] }]
  end
end

class Time
  def to_jsonify
    utc.strftime('%FT%T.%L%z')
  end
end
