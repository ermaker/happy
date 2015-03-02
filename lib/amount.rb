require 'bigdecimal'

class Amount < Currency
  include Comparable

  def initialize value, currency
    replace(
      self.class[
        Currency::CURRENCY[currency].merge('value' => value)
      ])
  end

  def self.[](*args)
    hash = super
    hash['value'] =
      BigDecimal.new(hash['value']) if hash.key?('value')
    hash
  end

  def to_s opt = {}
    value = self['value']
    value = value.round(opt[:round]) if opt.key? :round
    to_s_impl(value.to_s('F'), super)
  end

  def to_human opt = {}
    value = self['value']
    value = value.round(opt[:round]) if opt.key? :round
    "#{value.to_s('F')}#{self['currency']}"
  end

  def + rhs
    fail unless same_currency?(rhs)
    merge('value' => self['value'] + rhs['value'])
  end

  def - rhs
    fail unless same_currency?(rhs)
    merge('value' => self['value'] - rhs['value'])
  end

  def * rhs
    merge('value' => self['value'] * rhs['value'])
  end

  def / rhs
    merge('value' => self['value'] / rhs['value'])
  end

  def -@
    merge('value' => -self['value'])
  end

  def <=> rhs
    self['value'] <=> rhs['value']
  end

  XCOIN_ANTI_FEE_RATIO = '0.999'
  PAXMONETA_ANTI_FEE_RATIO = '0.995'
  BTC_FEE = '0.0002'
  BTC2BTCXRP_FEE = Amount.new('0.01', 'XRP')
  XRP_FEE = Amount.new('0.012', 'XRP')
end

