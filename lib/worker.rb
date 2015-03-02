require 'simulator'

class Worker
	attr_accessor :address, :secret, :amounts, :paxmoneta_tag
	def initialize address, secret, paxmoneta_tag
		@address = address
		@secret = secret
		@paxmoneta_tag = paxmoneta_tag
		@amounts = AmountHash.new
	end

	def balances
		response = HTTParty.get("https://api.ripple.com/v1/accounts/#{@address}/balances")
			.parsed_response
                fail response.inspect unless response['success']
		response
	end

	def balances_safe
		loop do
			begin
				return balances
			rescue
			end
			sleep 5
		end
	end

        def order_book base, counter
                limit = 200
                response = HTTParty.get(
                        "https://api.ripple.com/v1/accounts/#{@address}/order_book/#{base.currency}/#{counter.currency}",
                        query: {limit: limit})
                        .parsed_response
                fail response.inspect unless response['success']
                response
        end

	def place_order base, counter
		body = {
			secret: secret,
			order: {
				type: 'sell',
				taker_gets: base,
				taker_pays: counter,
			},
		}
		response = HTTParty.post(
			"https://api.ripple.com/v1/accounts/#{@address}/orders",
			query: { validated: true },
			body: body.to_json,
			headers: { 'Content-Type' => 'application/json' })
			.parsed_response
		fail response.inspect unless response['success']
		response
	end

	def order_transaction hash
		response = HTTParty.get(
			"https://api.ripple.com/v1/accounts/#{@address}/orders/#{hash}")
			.parsed_response
		fail response.inspect unless response['success']
		fail response.inspect unless response['order_changes'].empty?
		response
	end

	def exchange base, counter, price
		base = @amounts[base]
		base -= Amount::XRP_FEE +
			Amount::XRP_FEE if base.same_currency? Currency::XRP
		counter = price * base
		hash = place_order(base, counter)['hash']
		order_transaction(hash)['balance_changes']
			.map { |amount| Amount[amount] }
			.map { |amount| @amounts.apply(amount) }
	end

	def btc_p2xrp price
		exchange(Currency::BTC_P, Currency::XRP, price)
	end

	def xrp2krw_p price
		exchange(Currency::XRP, Currency::KRW_P, price)
	end

	def prepare_payment amount
		response = HTTParty.get(
			"https://api.ripple.com/v1/accounts/#{@address}/payments/paths/#{amount['counterparty']}/#{amount}",
			query: { source_currencies: amount.currency.to_s.gsub('+', ' ') })
			.parsed_response
		fail response.inspect unless response['success']
		fail response.inspect unless response['payments'].one?
		response
	end

	def uuid
		response = HTTParty.get("https://api.ripple.com/v1/uuid")
			.parsed_response
		fail response.inspect unless response['success']
		response
	end

	def submit_payment payment
		body = {
			secret: secret,
			client_resource_id: uuid['uuid'],
			payment: payment,
		}
		response = HTTParty.post(
			"https://api.ripple.com/v1/accounts/#{@address}/payments",
			query: { validated: true },
			body: body.to_json,
			headers: { 'Content-Type' => 'application/json' })
			.parsed_response
		fail response.inspect unless response['success']
		response
	end

	def send_payment amount
		fail amount.to_s unless amount.same_currency? Currency::KRW_P
		payment = prepare_payment(amount)['payments'][0]
		payment['destination_tag'] = @paxmoneta_tag
		response = submit_payment(payment)
		response['payment']['source_balance_changes']
			.map { |amount| amount.merge('counterparty' => amount['issuer']) }
			.map { |amount| Amount[amount] }
			.map { |amount| @amounts.apply(amount) }

		response['payment']['destination_balance_changes']
			.map { |amount| amount.merge('counterparty' => amount['issuer']) }
			.map do |amount|
				if amount['counterparty'] == address
					amount['counterparty'] = Currency::KRW_R['counterparty']
				end
				amount
			end
			.map { |amount| Amount[amount] }
			.map { |amount| @amounts.apply(amount) }
		response
	end

	def krw_p2krw_r
		send_payment @amounts[Currency::KRW_P]
	end
end
