require 'happy'
require 'pp'

#Happy.logger.level = Logger::INFO

def test(base, counter, time)
  lm = Happy::LoggedMarket.new
  market = lm.market(base, counter, time)
  market.first['price']['value'].to_s('F')
end

gap_time = 60 * 60
after_time = Time.now - 5 * 60
base_time = after_time - gap_time

pp test(Happy::Currency::KRW_X, Happy::Currency::BTC_X, base_time)
pp test(Happy::Currency::BTC_P, Happy::Currency::XRP, after_time)
pp test(Happy::Currency::XRP, Happy::Currency::KRW_P, after_time)
