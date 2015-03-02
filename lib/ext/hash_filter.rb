class Hash
  def filter *args
    Hash[select { |key| args.include?(key) }]
  end
end
