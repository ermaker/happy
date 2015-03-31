require 'happy'

KRW_R = Happy::Currency::KRW_R
KRW_X = Happy::Currency::KRW_X
BTC_X = Happy::Currency::BTC_X
BTC_BS = Happy::Currency::BTC_BS
BTC_BSR = Happy::Currency::BTC_BSR
XRP = Happy::Currency::XRP
KRW_P = Happy::Currency::KRW_P

C = Happy::Worker::ExchangeWorker::Simulated
# E = Happy::Worker::ExchangeWorker
SE = Happy::Worker::ExchangeWorker::Simulated

job = Happy::Job.new

=begin
job.jobs = [
  [
    { 'queue' => 'krw_r', 'class' => C, 'args' => [KRW_R, KRW_X] }
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
  { 'queue' => 'krw_p', 'class' => C, 'args' => [KRW_P, KRW_R] }
]
=end

job.jobs = [
  [
    { 'queue' => 'krw_r', 'class' => C, 'args' => [KRW_R, KRW_P] }
  ],
  { 'queue' => 'simulate', 'class' => SE, 'args' => [KRW_R, KRW_P] },
  { 'queue' => 'krw_p', 'class' => C, 'args' => [KRW_P, XRP] },
  { 'queue' => 'xrp', 'class' => C, 'args' => [XRP, BTC_BSR] },
  [
    { 'queue' => 'btc_bsr', 'class' => C, 'args' => [BTC_BSR, BTC_BS] }
  ],
  { 'queue' => 'simulate', 'class' => SE, 'args' => [BTC_BSR, BTC_BS] },
  [
    { 'queue' => 'btc_bs', 'class' => C, 'args' => [BTC_BS, BTC_X] }
  ],
  { 'queue' => 'simulate', 'class' => SE, 'args' => [BTC_BS, BTC_X] },
  { 'queue' => 'btc_x', 'class' => C, 'args' => [BTC_X, KRW_X] },
  { 'queue' => 'krw_x', 'class' => C, 'args' => [KRW_X, KRW_R] }
]

job.local['balances'].apply('100000'.currency('KRW_R'))

job.work
