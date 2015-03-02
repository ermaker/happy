require 'require_all'

class BigDecimal
  def to_jsonify
    { value: to_f, raw: to_s }
  end
end

$logstash.with(type: 'test').at_once(norm: true) do |l|
  l.stash(
    pays: Amount.new('270000', 'KRW_X'),
    gets: Amount.new('1', 'BTC_X')
  )
  l.stash(
    pays: Amount.new('275000', 'KRW_X'),
    gets: Amount.new('1', 'BTC_X')
  )
  l.stash(
    pays: Amount.new('265000', 'KRW_X'),
    gets: Amount.new('1', 'BTC_X')
  )

  l.stash(
    pays: Amount.new('1', 'BTC_X'),
    gets: Amount.new('260000', 'KRW_X')
  )
  l.stash(
    pays: Amount.new('1', 'BTC_X'),
    gets: Amount.new('250000', 'KRW_X')
  )
  l.stash(
    pays: Amount.new('1', 'BTC_X'),
    gets: Amount.new('255000', 'KRW_X')
  )
end
