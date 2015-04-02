module Happy
  class BitStampWorker

    def main
      prev = fetch_fails
      loop do
        begin
          now = fetch_fails
          (now - prev).each do |item|
            retry_(item)
          end
          prev = now
        rescue => e
          Happy.logger.warn { e.class }
          Happy.logger.warn { e }
          Happy.logger.warn { e.backtrace.join("\n") }
        end
        sleep 60
      end
    end

    def fetch_fails
      worker = Worker.new
      worker.extend(BitStamp::Information)
      HTTParty.post(
        'https://www.bitstamp.net/api/withdrawal_requests/',
        body: worker.signature_hash
      ).parsed_response.select {|item| item['status'] == '4' }
    rescue => e
      Happy.logger.warn { e.class }
      Happy.logger.warn { e }
      Happy.logger.warn { e.backtrace.join("\n") }
      sleep 3
      retry
    end

    def retry_(item)
      Happy.logger.debug { "item: #{item}" }

      amount = item['amount'].currency('BTC_BS')
      order_time = Time.parse(item['datetime'] + 'Z')
      time = "#{((Time.now - order_time) / 60).round(2)}m"
      id = item['id']

      job = Job.new
      job.balances.apply(amount)
      case item['type']
      when 1
        job.jobs = [
          {
            'queue' => 'btc_bs',
            'class' => Worker::ExchangeWorker,
            'args' => [Currency::BTC_BS, Currency::BTC_X]
          }
        ]
        path = 'BS/XCOIN'
      when 7
        job.jobs = [
          {
            'queue' => 'btc_bs',
            'class' => Worker::ExchangeWorker,
            'args' => [Currency::BTC_BS, Currency::BTC_BSR]
          }
        ]
        path = 'BS/XRP'
      else
      end

      Happy.logger.debug { "Retry: BitStamp failover: #{time}, #{path}, #{amount.to_human}, #{id}, #{order_time}" }
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_process',
        type: 'note',
        title: 'Retry: BitStamp failover',
        body: "#{time}\n#{path}\n#{amount.to_human}\nid: #{id}\n#{order_time}"
      )

      job.work
    rescue => e
      Happy.logger.warn { e.class }
      Happy.logger.warn { e }
      Happy.logger.warn { e.backtrace.join("\n") }
      MShard::MShard.new.set_safe(
        pushbullet: true,
        channel_tag: 'morder_process',
        type: 'note',
        title: 'Fail: BitStamp failover',
        body: "#{item}\n#{e}"
      )
    end
  end
end
