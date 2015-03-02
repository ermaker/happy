# encoding: utf-8

require 'env'
require 'simulator'
require 'xcoin'
require 'worker'

def go btc_x
        price_xrp_btc_p = Amount.new('10000.0', 'XRP')
        price_krw_p_xrp = Amount.new('5.0', 'KRW_P')

	xcoin_user = ENV['XCOIN_USER']
	xcoin_password = ENV['XCOIN_PASSWORD']
	xcoin_password2 = ENV['XCOIN_PASSWORD2']
        address = ENV['XRP_ADDRESS']
        secret = ENV['XRP_SECRET']
        paxmoneta_tag = ENV['PAXMONETA_TAG']

	xcoin = XCoin.new(xcoin_user, xcoin_password, xcoin_password2)

	xcoin.ensure_login
	xcoin.buy btc_x
	krw_x, btc_x = xcoin.status
	krw_r = Amount.new(krw_x['value'], 'KRW_R')
	$logger.debug { "krw_r: #{krw_r}" }
	$logger.debug { "btc_x: #{btc_x}" }
	destination_address = ENV['BTC2RIPPER_ADDRESS']
	xcoin.send_(destination_address, btc_x)
	btc_x -= Amount.new(Amount::BTC_FEE, 'BTC_X')

	btc_p = Amount.new(btc_x['value'], 'BTC_P')

        worker = Worker.new(address, secret, paxmoneta_tag)
        MShard::MShard.new.set(
                pushbullet: true,
                channel_tag: 'morder_process',
                type: 'note',
                title: 'Wait Order',
                body: "#{krw_r.to_human} #{btc_p.to_human}"
        )
        balances = loop do
                balances = worker.balances_safe['balances']
                balances.map! { |a| Amount[a] }
                balances_btc_p = balances.find { |a| a.same_currency? Currency::BTC_P } || Amount.new('0', 'BTC_P')
                break balances if balances_btc_p >= btc_p
		sleep 3
        end
        MShard::MShard.new.set(
                pushbullet: true,
                channel_tag: 'morder_process',
                type: 'note',
                title: 'Start Order',
                body: balances.join("\n")
        )
        worker.amounts.apply(btc_p)
        worker.btc_p2xrp price_xrp_btc_p
        worker.xrp2krw_p price_krw_p_xrp

	if false # Do krw_p2krw_r?
		# For krw_p2krw_r
		worker.krw_p2krw_r 
		benefit = worker.amounts[Currency::KRW_R]
	else
		# For NO krw_p2krw_r
		benefit = worker.amounts[Currency::KRW_P] 
	end

        return [
		Amount.new('0.995', 'KRW_R') * benefit - krw_r,
		krw_r
	]
rescue => e
	$logger.warn { e.class }
	$logger.warn { e }
	$logger.warn { e.backtrace.join("\n") }
        MShard::MShard.new.set(
                pushbullet: true,
                channel_tag: 'morder_process',
                type: 'link',
                title: e.class.to_s,
                contents: <<-CONTENTS,
<pre>
#{e.class}
#{e}
#{e.backtrace.join("\n")}
</pre>
                CONTENTS
        )
end

begin
	$logger.debug { 'loop start' }
        loop do
		$logger.debug { 'check' }
                btc_x_value = MShard::MShard.new.get('order_btc_xrp_krw')
                unless btc_x_value.empty?
                        MShard::MShard.new.set(
                                id: 'order_btc_xrp_krw',
                                contents: '')
                        MShard::MShard.new.set(
                                pushbullet: true,
                                channel_tag: 'morder_process',
                                type: 'note',
                                title: 'Got Order',
                                body: btc_x_value
                        )
			btc_x = Amount.new(btc_x_value, 'BTC_X')
			benefit, krw_r = go(btc_x)
                        percent = ((benefit/krw_r)['value'] * 100).round(2).to_s('F')
                        title = "#{benefit.to_human(round: 2)}(#{percent}%)"
                        body = "#{benefit.to_s(round: 2)} (#{percent}% of #{krw_r.to_s(round: 2)})"

                        MShard::MShard.new.set(
                                pushbullet: true,
                                channel_tag: 'morder_process',
                                type: 'note',
                                title: title,
                                body: body,
                        )
                end
		$logger.debug { 'sleep' }
                sleep 30
        end
rescue => e
        MShard::MShard.new.set(
                pushbullet: true,
                channel_tag: 'morder_process',
                type: 'link',
                title: e.class.to_s,
                contents: <<-CONTENTS,
<pre>
#{e.class}
#{e}
#{e.backtrace.join("\n")}
</pre>
                CONTENTS
        )
end

