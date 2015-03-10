module Happy
  module PaxMoneta
    module Information
      attr_accessor :paxmoneta_tag

      def self.extended(mod)
        mod.paxmoneta_tag = ENV['PAXMONETA_TAG']
      end
    end

    module Exchange
      def self.extended(mod)
        [
          [Happy::Currency::KRW_P, Happy::Currency::KRW_R]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_paxmoneta)
        end
      end

      def exchange_paxmoneta_prepare_payment(amount)
        response = HTTParty.get(
          "https://api.ripple.com/v1/accounts/#{xrp_address}/payments/paths/#{amount['counterparty']}/#{amount}",
          query: { source_currencies: amount.currency.to_s.gsub('+', ' ') })
                   .parsed_response
        fail response.inspect unless response['success']
        fail response.inspect unless response['payments'].one?
        response
      end

      def exchange_paxmoneta_uuid
        response = HTTParty.get('https://api.ripple.com/v1/uuid')
                   .parsed_response
        fail response.inspect unless response['success']
        response
      end

      def exchange_paxmoneta_submit_payment(payment)
        body = {
          secret: xrp_secret,
          client_resource_id: exchange_paxmoneta_uuid['uuid'],
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
      end

      def send_paxmoneta(amount, counter)
        # TODO: assert counter
        fail amount.to_s unless amount.same_currency? Currency::KRW_P
        payment = exchange_paxmoneta_prepare_payment(amount)['payments'][0]
        payment['destination_tag'] = paxmoneta_tag
        response = exchange_paxmoneta_submit_payment(payment)
        result = AmountHash.new.tap do |ah|
          response['payment']['source_balance_changes']
            .map { |amount| amount.merge('counterparty' => amount['issuer']) }
            .to_objectify.each do |amount|
            ah.apply(amount)
          end

          response['payment']['destination_balance_changes']
            .map { |amount| amount.merge('counterparty' => amount['issuer']) }
            .map do |amount|
            if amount['counterparty'] == xrp_address
              amount['counterparty'] = counter['counterparty']
            end
            amount
          end.to_objectify.each do |amount|
            ah.apply(amount *
              Amount.new(PAXMONETA_ANTI_FEE_RATIO, 'KRW_R'))
          end
        end
        result
      end
    end

    module SimulatedExchange
      def self.extended(mod)
        [
          [Happy::Currency::KRW_P, Happy::Currency::KRW_R]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_paxmoneta_simulated)
        end
      end

      def send_paxmoneta_simulated(amount, counter)
        # TODO: assert counter
        fail amount.to_s unless amount.same_currency? Currency::KRW_P
        result = AmountHash.new.tap do |ah|
          ah.apply(-amount)
          ah.apply(-Amount::XRP_FEE)
          ah.apply(
            Amount.new(Amount::PAXMONETA_ANTI_FEE_RATIO, counter) *
            amount)
        end
        result
      end
    end
  end
end
