class Object
  def currency(currency_)
    Happy::Amount.new(self, currency_)
  end
end
