module Happy
  class Currency < Hash
    BTC_X = self[
      'currency' => 'BTC',
      'counterparty' => 'XCoin',
    ]
    BTC_B2R = self[
      'currency' => 'BTC',
      'counterparty' => 'Gateway_btc2ripple',
    ]
    BTC_P = self[
      'currency' => 'BTC',
      'counterparty' => 'rMwjYedjc7qqtKYVLiAccJSmCwih4LnE2q',
    ]
    BTC_BS = self[
      'currency' => 'BTC',
      'counterparty' => 'BitStamp',
    ]
    BTC_BSR = self[
      'currency' => 'BTC',
      'counterparty' => 'rvYAfWj5gh67oV6fW32ZzP3Aw4Eubs59B',
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
      'BTC_B2R' => BTC_B2R, BTC_B2R => BTC_B2R,
      'BTC_P' => BTC_P, BTC_P => BTC_P,
      'BTC_BS' => BTC_BS, BTC_BS => BTC_BS,
      'BTC_BSR' => BTC_BSR, BTC_BSR => BTC_BSR,
      'XRP' => XRP, XRP => XRP,
      'KRW_X' => KRW_X, KRW_X => KRW_X,
      'KRW_P' => KRW_P, KRW_P => KRW_P,
      'KRW_R' => KRW_R, KRW_R => KRW_R
    }

    def self.[](*args)
      hash = super
      hash['counterparty'] = '' unless hash.key?('counterparty')
      hash
    end

    def to_s_impl(*args)
      args.compact.reject(&:empty?).join('+')
    end

    def to_s(*_args)
      to_s_impl(self['currency'], self['counterparty'])
    end

    def to_human
      merge('counterparty' => self['counterparty'][0, 8]).to_s
    end

    def same_currency?(rhs)
      currency == rhs.currency
    end

    def currency
      Currency[%w(currency counterparty).map { |k| [k, self[k]] }]
    end

    def with value
      Happy::Amount.new(value, currency)
    end
  end
end
