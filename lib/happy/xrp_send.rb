module Happy
  module XRPSend
    module Exchange
      def self.extended(mod)
        [
          [Currency::KRW_P, Currency::KRW_R],
          [Currency::BTC_BSR, Currency::BTC_BS]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xrpsend_websocket)
        end
      end

      def exchange_xrpsend_prepare_payment(amount)
        response = HTTParty.get(
          "https://api.ripple.com/v1/accounts/#{xrp_address}/payments/paths/#{amount['counterparty']}/#{amount}",
          query: { source_currencies: amount.currency.to_s.gsub('+', ' ') })
                   .parsed_response
        fail response.inspect unless response['success']
        fail response.inspect unless response['payments'].one?
        response
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        MShard::MShard.new.set_safe(
          pushbullet: true,
          channel_tag: 'morder_process',
          type: 'note',
          title: 'Retry: exchange_xrpsend_prepare_payment',
          body: "#{e.message}"
        )
        raise
      end

      def exchange_xrpsend_uuid
        response = HTTParty.get('https://api.ripple.com/v1/uuid')
                   .parsed_response
        fail response.inspect unless response['success']
        response
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        MShard::MShard.new.set_safe(
          pushbullet: true,
          channel_tag: 'morder_process',
          type: 'note',
          title: 'Retry: exchange_xrpsend_uuid',
          body: "#{e.message}"
        )
        raise
      end

      def exchange_xrpsend_submit_payment(payment)
        body = {
          secret: xrp_secret,
          client_resource_id: exchange_xrpsend_uuid['uuid'],
          payment: payment
        }
        response = HTTParty.post(
          "https://api.ripple.com/v1/accounts/#{xrp_address}/payments",
          query: { validated: true },
          body: body.to_json,
          headers: { 'Content-Type' => 'application/json' })
                   .parsed_response
        fail response.inspect unless response['success']
        response
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        MShard::MShard.new.set_safe(
          pushbullet: true,
          channel_tag: 'morder_process',
          type: 'note',
          title: 'Retry: exchange_xrpsend_submit_payment',
          body: "#{e.message}"
        )
        raise
      end

      SEND_XRPSEND_DESTINATION_TAG = {
        Currency::KRW_P => ENV['PAXMONETA_TAG'],
        Currency::BTC_BSR => ENV['BITSTAMP_TAG']
      }

      SEND_XRPSEND_ANTI_FEE_RATIO = {
        Currency::KRW_P => Amount::PAXMONETA_ANTI_FEE_RATIO,
        Currency::BTC_BSR => BigDecimal.new('1')
      }

      def send_xrpsend(amount, counter)
        payment = exchange_xrpsend_prepare_payment(amount)['payments'][0]
        payment['destination_tag'] = SEND_XRPSEND_DESTINATION_TAG[amount.currency]
        response = exchange_xrpsend_submit_payment(payment)

        ah = AmountHash.new

        balances =
          response['payment']['source_balance_changes']
            .map { |amount| amount.merge('counterparty' => amount['issuer']) }
        ah.apply(balances)

        balances =
          response['payment']['destination_balance_changes']
            .map { |amount| amount.merge('counterparty' => amount['issuer']) }
            .map do |amount|
            if amount['counterparty'] == xrp_address
              amount['counterparty'] = counter['counterparty']
            end
            amount
          end.to_objectify.map do |amount_|
          amount_ * SEND_XRPSEND_ANTI_FEE_RATIO[amount.currency]
        end
        ah.apply(balances)
      rescue
        sleep 0.3
        retry
      end

      def send_xrpsend_websocket(amount, _)
        Happy::Util::XRPWebSocket.new do |ws|
          begin
            signed = ws.request(
              command: 'sign',
              tx_json: {
                TransactionType: 'Payment',
                Account: ENV['XRP_ADDRESS'],
                Destination: amount['counterparty'],
                DestinationTag: SEND_XRPSEND_DESTINATION_TAG[amount.currency],
                Fee: '10000',
                Amount: amount.merge(issuer: amount['counterparty'])
              },
              secret: ENV['XRP_SECRET']
            )
            fail signed.to_s unless signed['status'] == 'success'
            result = ws.request(
              command: 'submit',
              tx_blob: signed['result']['tx_blob']
            )
            fail result.to_s unless signed['status'] == 'success'

          rescue
            sleep 0.3
            retry
          end
        end
        AmountHash.new # TODO: Calculate
      end
    end

    module SimulatedExchange
      def self.extended(mod)
        [
          [Currency::KRW_P, Currency::KRW_R],
          [Currency::BTC_BSR, Currency::BTC_BS]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_xrpsend_simulated)
        end
      end

      SEND_XRPSEND_ANTI_FEE_RATIO = {
        Currency::KRW_P => Amount::PAXMONETA_ANTI_FEE_RATIO,
        Currency::BTC_BSR => BigDecimal.new('1')
      }

      def send_xrpsend_simulated(amount, counter)
        AmountHash.new.apply(
          -amount,
          -Amount::XRP_FEE,
          counter.with(amount) * SEND_XRPSEND_ANTI_FEE_RATIO[amount.currency]
        )
      end
    end
  end
end
