require 'env'
require 'simulator'

def go base, base_sim
	sim = Simulator.new(base_sim.address)
	sim.xcoin_bids = base_sim.xcoin_bids
	sim.bids = base_sim.bids

	sim.amounts.apply(base)
	sim.krw_r2krw_x
	btc_x = sim.xxx(Currency::BTC_X, sim.amounts[Currency::KRW_X])
	sim.krw_x2btc_x
	sim.btc_x2btc_btcxrp
	sim.btc_btcxrp2btc_p
	sim.btc_p2xrp
	sim.xrp2krw_p
	sim.krw_p2krw_r
	benefit = sim.amounts[base.currency] - base
	[benefit, base, btc_x, sim]
end

puts
puts '=' * 50
puts 'Prepare start'
address = ENV['XRP_ADDRESS']
base_sim = Simulator.new(address)
puts 'XCoin'
base_sim.xcoin_bids
puts 'XRP'
base_sim.bids[[Currency::BTC_P, Currency::XRP]]
puts 'XRP'
base_sim.bids[[Currency::XRP, Currency::KRW_P]]
puts 'Prepare end'

result = (BigDecimal.new('100000')..BigDecimal.new('8000000'))
	.step(BigDecimal.new('100000')).map do |value|
	base = Amount.new(value, 'KRW_R')
	go base, base_sim
end.sort.map do |benefit,base,btc_x,sim|
	[
		((benefit/base)['value'] * 100).round(2).to_s('F') + '%',
		benefit.to_human(round: 2),
		"#{(base['value'] / 100000).to_i}-KRW",
		btc_x.to_human(round:4),
		sim
	]
end
output = result.map do |percent,benefit,base,btc_x,_|
	"#{percent} #{benefit} #{base} #{btc_x}"
end

puts
puts "XCoin: #{base_sim.xcoin_bids[0][0]}KRW/BTC (#{base_sim.xcoin_bids[0][1]}BTC)"
puts output.join("\n")
puts

MShard::MShard.new.set(
	pushbullet: true,
	channel_tag: 'morder_status',
	type: 'link',
	title: output.last,
	body: output.reverse[1..-1].join("\n"),
	contents: <<-CONTENTS)
<pre>
XCoin: #{base_sim.xcoin_bids[0][0]} KRW/BTC (#{base_sim.xcoin_bids[0][1]} BTC)
#{output.reverse.join("\n")}
</pre>
CONTENTS
