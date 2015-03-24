require 'openssl'

module Happy
  module BitStamp
    module Information
      attr_accessor :bitstamp_id, :bitstamp_key, :bitstamp_secret

      def self.extended(mod)
        mod.bitstamp_id = ENV['BITSTAMP_ID']
        mod.bitstamp_key = ENV['BITSTAMP_KEY']
        mod.bitstamp_secret = ENV['BITSTAMP_SECRET']
      end

      def signature_hash
        nonce = Time.now.to_i.to_s
        message = nonce + bitstamp_id + bitstamp_key
        signature = OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest::SHA256.new,
          bitstamp_secret,
          message).upcase
        {
          key: bitstamp_key,
          signature: signature,
          nonce: nonce
        }
      end
    end

    module Balance
      def self.extended(mod)
        [
          Currency::BTC_BS
        ].each do |currency|
          mod.proc_balance[currency] = mod.method(:balance_bitstamp)
        end
      end

      def balance_bitstamp_impl
        response = HTTParty.post(
          'https://www.bitstamp.net/api/balance/',
          body: signature_hash
        ).parsed_response
        response['btc_available'].currency('BTC_BS')
      end

      def balance_bitstamp
        AmountHash.new.apply(balance_bitstamp_impl)
      end
    end

    module Exchange
      def self.extended(mod)
        [
          [Currency::BTC_BS, Currency::BTC_BSR]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_bitstamp)
        end
        [
          [Currency::BTC_BS, Currency::BTC_BS]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_bitstamp)
        end
      end

      def send_bitstamp(amount, counter)
        # XXX: Assumes amount is BTC_BS
        # XXX: Assumes counter is BTC_BSR
        address = xrp_address

        body = signature_hash.merge(
          amount: amount['value'].to_s('F'),
          address: address,
          currency: amount['currency']
        )
        response = HTTParty.post(
          'https://www.bitstamp.net/api/ripple_withdrawal/',
          body: body
        ).parsed_response
        fail response.to_s unless response == true
        AmountHash.new.apply(
          -amount,
          counter.with(amount)
        )
      end

      def wait_bitstamp(amount, _counter)
        wait(amount)
        AmountHash.new
      end
    end

    module SimulatedExchange
      def self.extended(mod)
        [
          [Currency::BTC_BS, Currency::BTC_BSR]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:send_bitstamp_simulated)
        end
        [
          [Currency::BTC_BS, Currency::BTC_BS]
        ].each do |base,counter|
          mod.proc_exchange[[base, counter]] = mod.method(:wait_bitstamp_simulated)
        end
      end

      def send_bitstamp_simulated(amount, counter)
        AmountHash.new.apply(
          -amount,
          counter.with(amount)
        )
      end

      def wait_bitstamp_simulated(_amount, _counter)
        AmountHash.new
      end
    end
  end
end
