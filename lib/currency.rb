class Currency < Hash
  BTC_X = self[
    'currency' => 'BTC',
    'counterparty' => 'XCoin',
  ]
  BTC_BTCXRP = self[
    'currency' => 'BTC',
    'counterparty' => 'Gateway_btc2ripple',
  ]
  BTC_P = self[
    'currency' => 'BTC',
    'counterparty' => 'rMwjYedjc7qqtKYVLiAccJSmCwih4LnE2q',
  ]
  XRP = self[
    'currency' => 'XRP',
    'counterparty' => '',
  ]
  KRW_X = self[
    'currency' => 'KRW',
    'counterparty' => 'XCoin',
  ]
  KRW_P = self[
    'currency' => 'KRW',
    'counterparty' => 'rUkMKjQitpgAM5WTGk79xpjT38DEJY283d',
  ]
  KRW_R = self[
    'currency' => 'KRW',
    'counterparty' => 'Real',
  ]
  CURRENCY = {
    'BTC_X' => BTC_X, BTC_X => BTC_X,
    'BTC_BTCXRP' => BTC_BTCXRP, BTC_BTCXRP => BTC_BTCXRP,
    'BTC_P' => BTC_P, BTC_P => BTC_P,
    'XRP' => XRP, XRP => XRP,
    'KRW_X' => KRW_X, KRW_X => KRW_X,
    'KRW_P' => KRW_P, KRW_P => KRW_P,
    'KRW_R' => KRW_R, KRW_R => KRW_R,
  }

  def self.[](*args)
    hash = super
    hash['counterparty'] = '' unless hash.key?('counterparty')
    hash
  end

  def to_s_impl *args
    args.compact.reject(&:empty?).join('+')
  end

  def to_s *args
    to_s_impl(self['currency'], self['counterparty'])
  end

  def same_currency? rhs
    ['currency', 'counterparty'].all? {|k| self[k] == rhs[k]}
  end

  def currency
    Currency[['currency', 'counterparty'].map { |k| [k, self[k]] }]
  end
end
