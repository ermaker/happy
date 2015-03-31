require 'happy'

BTC_BSR = Happy::Currency::BTC_BSR
XRP = Happy::Currency::XRP
KRW_P = Happy::Currency::KRW_P
KRW_R = Happy::Currency::KRW_R

XRP_SE = Happy::Worker::XRP::SimulatedExchange
XRP_E = Happy::Worker::XRP::Exchange

job = Happy::Job.new
# job.local['class'] = [
#   [
#     [BTC_BSR, XRP],
#     XRP_E
#   ],
#   [
#     [XRP, KRW_P],
#     XRP_E
#   ],
#   [
#     [KRW_P, KRW_R],
#     XRP_SE
#   ]
# ]

WT = Happy::Worker::WorkerTest

job.jobs = [
  { 'class' => WT, 'args' => [1] },
  [
    { 'class' => WT, 'args' => [3] }
  ],
  { 'class' => WT, 'args' => [3] }
]

# job.push_detail('class' => XRP_E, 'args' => [BTC_BSR, XRP])
# job.push_detail('class' => XRP_E, 'args' => [XRP, KRW_P])
# job.push_detail('class' => XRP_SE, 'args' => [KRW_P, KRW_R])

# job.local['balances'].apply('0.0001'.currency('BTC_BSR'))

job.work
