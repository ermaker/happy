module Happy
  class Auto
    METHOD = {
      'KRW/XCOIN/BS/XRP/PAX/KRW' => :krw_xcoin_bs_xrp_pax_krw,
      'KRW/XCOIN/B2R/XRP/PAX/KRW' => :krw_xcoin_b2r_xrp_pax_krw,
      # 'PAX/XRP/BS/XCOIN' => :pax_xrp_bs_xcoin,
      'KRW/PAX/XRP/BS/XCOIN/KRW' => :krw_pax_xrp_bs_xcoin_krw
    }

    def run_if_timing(path)
      best = Grader.new.timing?(path)
      return unless best
      _, base, _ = best
      krw_r = base
      method(METHOD[path]).call('krw_r' => krw_r, 'path' => path)
    end

    def main
      run_if_timing('KRW/PAX/XRP/BS/XCOIN/KRW')
      run_if_timing('KRW/XCOIN/B2R/XRP/PAX/KRW')
      run_if_timing('KRW/XCOIN/BS/XRP/PAX/KRW')
    end

    KRW_R = Currency::KRW_R
    KRW_X = Currency::KRW_X
    BTC_X = Currency::BTC_X
    BTC_BS = Currency::BTC_BS
    BTC_BSR = Currency::BTC_BSR
    BTC_B2R = Currency::BTC_B2R
    BTC_P = Currency::BTC_P
    XRP = Currency::XRP
    KRW_P = Currency::KRW_P

    L = Worker::Limit
    V = Worker::Volume
    E = Worker::ExchangeWorker
    SE = Worker::ExchangeWorker::Simulated
    N = Worker::Notifier
    C = E

    def krw_xcoin_bs_xrp_pax_krw(order)
      job = Job.new
      job.initial_balances = AmountHash.new.apply(
        order['krw_r'].currency('KRW_R'),
        -Amount::XRP_FEE * 2
      )
      job.path = order['path']
      job.jobs = [
        { 'queue' => 'simulate', 'class' => L, 'args' => [:limit, 'XCoin'] },
        { 'queue' => 'simulate', 'class' => V, 'args' => [:up, 'BTC/XRP'] },
        { 'queue' => 'simulate', 'class' => L, 'args' => [:update, 'XCoin'] },
        { 'queue' => 'simulate', 'class' => N, 'args' => [:start] },
        [
          { 'queue' => 'krw_r', 'class' => SE, 'args' => [KRW_R, KRW_X] }
        ],
        { 'queue' => 'simulate', 'class' => SE, 'args' => [KRW_R, KRW_X] },
        { 'queue' => 'krw_x', 'class' => C, 'args' => [KRW_X, BTC_X] },
        [
          { 'queue' => 'btc_x', 'class' => C, 'args' => [BTC_X, BTC_BS] }
        ],
        { 'queue' => 'simulate', 'class' => SE, 'args' => [BTC_X, BTC_BS] },
        [
          { 'queue' => 'btc_bs', 'class' => C, 'args' => [BTC_BS, BTC_BSR] }
        ],
        { 'queue' => 'simulate', 'class' => SE, 'args' => [BTC_BS, BTC_BSR] },
        { 'queue' => 'btc_bsr', 'class' => C, 'args' => [BTC_BSR, XRP] },
        { 'queue' => 'xrp', 'class' => C, 'args' => [XRP, KRW_P] },
        [
          { 'queue' => 'simulate', 'class' => V, 'args' => [:down, 'BTC/XRP'] }
        ],
        { 'queue' => 'krw_p', 'class' => SE, 'args' => [KRW_P, KRW_R] },
        { 'queue' => 'simulate', 'class' => N, 'args' => [:finish] }
      ]

      job.work
    end

    def krw_xcoin_b2r_xrp_pax_krw(order)
      job = Job.new
      job.initial_balances = AmountHash.new.apply(
        order['krw_r'].currency('KRW_R'),
        -Amount::XRP_FEE * 2
      )
      job.path = order['path']
      job.jobs = [
        { 'queue' => 'simulate', 'class' => L, 'args' => [:limit, 'XCoin'] },
        { 'queue' => 'simulate', 'class' => V, 'args' => [:up, 'BTC/XRP'] },
        { 'queue' => 'simulate', 'class' => L, 'args' => [:update, 'XCoin'] },
        { 'queue' => 'simulate', 'class' => N, 'args' => [:start] },
        [
          { 'queue' => 'krw_r', 'class' => SE, 'args' => [KRW_R, KRW_X] }
        ],
        { 'queue' => 'simulate', 'class' => SE, 'args' => [KRW_R, KRW_X] },
        { 'queue' => 'krw_x', 'class' => C, 'args' => [KRW_X, BTC_X] },
        [
          { 'queue' => 'btc_x', 'class' => C, 'args' => [BTC_X, BTC_B2R] }
        ],
        { 'queue' => 'simulate', 'class' => SE, 'args' => [BTC_X, BTC_B2R] },
        { 'queue' => 'btc_b2r', 'class' => SE, 'args' => [BTC_B2R, BTC_P] },
        { 'queue' => 'btc_p', 'class' => C, 'args' => [BTC_P, XRP] },
        { 'queue' => 'xrp', 'class' => C, 'args' => [XRP, KRW_P] },
        [
          { 'queue' => 'simulate', 'class' => V, 'args' => [:down, 'BTC/XRP'] }
        ],
        { 'queue' => 'krw_p', 'class' => SE, 'args' => [KRW_P, KRW_R] },
        { 'queue' => 'simulate', 'class' => N, 'args' => [:finish] }
      ]

      job.work
    end

    def krw_pax_xrp_bs_xcoin_krw(order)
      job = Job.new
      job.initial_balances = AmountHash.new.apply(
        order['krw_r'].currency('KRW_R'),
        -Amount::XRP_FEE * 2
      )
      job.path = order['path']
      job.jobs = [
        { 'queue' => 'simulate', 'class' => L, 'args' => [:limit, 'PaxMoneta'] },
        { 'queue' => 'simulate', 'class' => V, 'args' => [:up, 'XRP/BTC'] },
        { 'queue' => 'simulate', 'class' => L, 'args' => [:update, 'PaxMoneta'] },
        { 'queue' => 'simulate', 'class' => N, 'args' => [:start] },
        [
          { 'queue' => 'krw_r', 'class' => SE, 'args' => [KRW_R, KRW_P] }
        ],
        { 'queue' => 'simulate', 'class' => SE, 'args' => [KRW_R, KRW_P] },
        { 'queue' => 'krw_p', 'class' => C, 'args' => [KRW_P, XRP] },
        { 'queue' => 'xrp', 'class' => C, 'args' => [XRP, BTC_BSR] },
        [
          { 'queue' => 'simulate', 'class' => V, 'args' => [:down, 'XRP/BTC'] }
        ],
        [
          { 'queue' => 'btc_bsr', 'class' => C, 'args' => [BTC_BSR, BTC_BS] }
        ],
        { 'queue' => 'simulate', 'class' => SE, 'args' => [BTC_BSR, BTC_BS] },
        [
          { 'queue' => 'btc_bs', 'class' => C, 'args' => [BTC_BS, BTC_X] }
        ],
        { 'queue' => 'simulate', 'class' => SE, 'args' => [BTC_BS, BTC_X] },
        { 'queue' => 'btc_x', 'class' => C, 'args' => [BTC_X, KRW_X] },
        { 'queue' => 'krw_x', 'class' => SE, 'args' => [KRW_X, KRW_R] },
        { 'queue' => 'simulate', 'class' => N, 'args' => [:finish] }
      ]

      job.work
    end
  end
end
