require 'bigdecimal'

module Happy
  class Amount < Currency
    include Comparable

    def initialize(value, currency)
      replace(
        self.class[
          Currency::CURRENCY[currency].merge('value' => value)
        ])
    end

    def self.[](*args)
      hash = super
      if hash.key?('value')
        hash['value'] = BigDecimal.new(
          case
          when hash['value'].is_a?(Amount)
            hash['value']['value']
          when hash['value'].is_a?(Hash) && hash['value'].key?('raw')
            hash['value']['raw']
          when hash['value'].is_a?(String)
            hash['value'].gsub(',', '')
          else
            hash['value']
          end
        )
      end
      hash
    end

    def to_s(opt = {})
      value = self['value']
      value = value.round(opt[:round]) if opt.key? :round
      to_s_impl(value.to_s('F'), super)
    end

    def to_human(opt = {})
      value = self['value']
      value = value.round(opt[:round]) if opt.key? :round
      "#{value.to_s('F')}#{self['currency']}"
    end

    def coerce(rhs)
      [with(rhs), self]
    end

    def +(rhs)
      rhs = with(rhs) unless rhs.is_a?(self.class)
      fail unless same_currency?(rhs)
      merge('value' => self['value'] + rhs['value'])
    end

    def -(rhs)
      rhs = with(rhs) unless rhs.is_a?(self.class)
      self + (-with(rhs))
    end

    def *(rhs)
      merge('value' => self['value'] * with(rhs)['value'])
    end

    def /(rhs)
      self * (with(rhs).invert)
    end

    def -@
      merge('value' => -self['value'])
    end

    def invert
      merge('value' => 1 / self['value'])
    end

    def <=>(rhs)
      fail unless same_currency?(rhs)
      self['value'] <=> rhs['value']
    end

    XCOIN_ANTI_FEE_RATIO = '0.999'
    B2R_RIPPLE_FEE_RATIO = BigDecimal.new('0.002')
    BITSTAMP_RIPPLE_FEE_RATIO = BigDecimal.new('0.002')
    PAXMONETA_ANTI_FEE_RATIO = '0.995'
    BTC_FEE = '0.0002'
    BTC2BTCXRP_FEE = Amount.new('0.01', 'XRP')
    XRP_FEE = Amount.new('0.012', 'XRP')
  end
end
