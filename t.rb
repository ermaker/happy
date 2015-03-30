require 'happy'

BTC_BSR = Happy::Currency::BTC_BSR
XRP = Happy::Currency::XRP
KRW_P = Happy::Currency::KRW_P
KRW_R = Happy::Currency::KRW_R

XRP_SE = Happy::Worker::XRP::SimulatedExchange
XRP_E = Happy::Worker::XRP::Exchange

job = Happy::Job.new
job.local['class'] = [
  [
    [BTC_BSR, XRP],
    XRP_E
  ],
  [
    [XRP, KRW_P],
    XRP_E
  ],
  [
    [KRW_P, KRW_R],
    XRP_SE
  ]
]
job.local['balances'].apply('0.0001'.currency('BTC_BSR'))

job.push(BTC_BSR, XRP)
job.push(XRP, KRW_P)
job.push(KRW_P, KRW_R)

job.work
