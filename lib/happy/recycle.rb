module Happy
  class Recycle
    def main
      krw_r_value = MShard::MShard.new.get_safe('order_krw_xrp_btc_krw')
      return if krw_r_value.empty?
      MShard::MShard.new.set_safe(
        id: 'order_krw_xrp_btc_krw',
        contents: '')
      krw_r = Amount.new(krw_r_value, 'KRW_R')
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_process',
        type: 'note',
        title: "R] Got Order: #{krw_r.to_human}",
        body: "#{krw_r}"
      )
      run(krw_r)
    end

    def run(krw_r)
      worker = Worker.new
      worker.extend(XCoin::Information)
      worker.extend(XRP::Information)
      worker.extend(BitStamp::Information)
      worker.extend(Worker::Balance)
      # worker.extend(Logged::Balance) # TODO
      worker.extend(XCoin::Balance)
      worker.extend(BitStamp::Balance)
      worker.extend(XRP::Balance)
      # worker.extend(Simulator::Balance)
      worker.extend(Worker::Market)
      worker.extend(Logged::Market)
      # worker.extend(XCoin::Market)
      # worker.extend(XRP::Market)
      worker.extend(Worker::Exchange)
      worker.extend(Real::SimulatedExchange)
      worker.extend(XCoin::Exchange)
      # worker.extend(XCoin::SimulatedExchange)
      # worker.extend(B2R::SimulatedExchange)
      worker.extend(BitStamp::Exchange)
      worker.extend(XRP::Exchange)
      # worker.extend(XRP::SimulatedExchange)
      worker.extend(XRPSend::Exchange)
      # worker.extend(XRPSend::SimulatedExchange)

      Happy.logger.info { "Order Start: #{krw_r}" }
      worker.initial_balance = krw_r

      # Use inner amount
      worker.local_balances.apply(-krw_r)
      worker.local_balances.apply(krw_r['value'].currency('KRW_P'))

      worker.local_balances.apply(-Amount::XRP_FEE)
      worker.local_balances.apply(-Amount::XRP_FEE)
      Happy.logger.info { "local_balances: #{worker.local_balances}" }
      [
        # Currency::KRW_R,
        Currency::KRW_P,
        Currency::KRW_P,
        Currency::XRP,
        Currency::BTC_BSR,
        Currency::BTC_BS,
        Currency::BTC_BS,
        Currency::BTC_X,
        Currency::BTC_X,
        Currency::KRW_X # ,
        # Currency::KRW_R
      ].each_cons(2) do |base,counter|
        result = worker.exchange(worker.local_balances[base], counter)
        Happy.logger.debug { "result: #{result}" }
        Happy.logger.info { "local_balances: #{worker.local_balances}" }
      end

      # Do not withdrawal
      worker.local_balances.apply(
        -worker.local_balances[Currency::KRW_X],
        worker.local_balances[Currency::KRW_X]['value'].currency(Currency::KRW_R)
      )

      Happy.logger.info { "local_balances: #{worker.local_balances}" }

      Happy.logger.info { "benefit: #{worker.benefit}" }
      percent = (worker.benefit/worker.initial_balance * 100)['value']
        .round(2).to_s('F')
      percent = "#{percent}%"
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_process',
        type: 'note',
        title: "R] #{worker.benefit.to_human(round: 2)}(#{percent})",
        body: "#{worker.initial_balance.to_human}"
      )
    end
  end
end
