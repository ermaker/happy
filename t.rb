require 'happy'

KRW_R = Happy::Currency::KRW_R
KRW_X = Happy::Currency::KRW_X
BTC_X = Happy::Currency::BTC_X
BTC_BS = Happy::Currency::BTC_BS
BTC_BSR = Happy::Currency::BTC_BSR
XRP = Happy::Currency::XRP
KRW_P = Happy::Currency::KRW_P

E = Happy::Worker::XRP::Exchange
SE = Happy::Worker::XRP::SimulatedExchange

job = Happy::Job.new

job.jobs = [
  [
    { 'queue' => 'krw_r', 'class' => SE, 'args' => [KRW_R, KRW_X] }
  ],
  { 'queue' => 'simulate', 'class' => SE, 'args' => [KRW_R, KRW_X] },
  { 'queue' => 'krw_x', 'class' => SE, 'args' => [KRW_X, BTC_X] },
  [
    { 'queue' => 'btc_x', 'class' => SE, 'args' => [BTC_X, BTC_BS] }
  ],
  { 'queue' => 'simulate', 'class' => SE, 'args' => [BTC_X, BTC_BS] },
  [
    { 'queue' => 'btc_bs', 'class' => SE, 'args' => [BTC_BS, BTC_BSR] }
  ],
  { 'queue' => 'simulate', 'class' => SE, 'args' => [BTC_BS, BTC_BSR] },
  { 'queue' => 'btc_bsr', 'class' => SE, 'args' => [BTC_BSR, XRP] },
  { 'queue' => 'xrp', 'class' => SE, 'args' => [XRP, KRW_P] },
  { 'queue' => 'krw_p', 'class' => SE, 'args' => [KRW_P, KRW_R] }
]

job.local['balances'].apply('100000'.currency('KRW_R'))

job.work
