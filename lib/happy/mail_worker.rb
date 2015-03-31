require 'nokogiri'
require 'mail'

module Happy
  class MailWorker
    Mail.defaults do
      retriever_method(
        :imap,
        address: 'imap.gmail.com',
        port: 993,
        user_name: ENV['EMAIL_USERNAME'],
        password: ENV['EMAIL_PASSWORD'],
        enable_ssl: true
      )
    end

    def main
      Mail.find(delete_after_find: true).each do |mail|
        Happy.logger.debug { "mail: #{mail.subject}" }
        click mail if mail.subject =~ /출금요청/
        put mail if mail.subject =~ /Forwarded Message from /
      end
    end

    def click(mail)
      Happy.logger.debug { 'click' }
      body = mail.parts.find { |part| part.content_type =~ %r{^text/html} }.body.to_s
      html = Nokogiri.HTML(body)
      link = html.xpath('//a[text()="여기를 클릭하세요!"]/@href').text
      Happy.logger.info { "link: #{link}" }
      begin
        worker = Worker.new
        worker.extend(XCoin::Information)
        worker.xcoin_ensure_login
        worker.xcoin_session.visit link
      rescue => e
        Happy.logger.warn { e.class }
        Happy.logger.warn { e }
        Happy.logger.warn { e.backtrace.join("\n") }
        sleep 0.3
        retry
      end
    rescue => e
      Happy.logger.warn { e.class }
      Happy.logger.warn { e }
      Happy.logger.warn { e.backtrace.join("\n") }
    end

    def put(mail)
      Happy.logger.debug { 'put' }
      if matched = mail.body.to_s.match(/XCOIN Verification Code : (\d+)/)
        Happy.logger.info { "SMS: #{matched[1]}" }
        MShard::MShard.new.set_safe(
          id: 'xcoin_sms_validation_code',
          contents: matched[1]
        )
      end
    rescue => e
      Happy.logger.warn { e.class }
      Happy.logger.warn { e }
      Happy.logger.warn { e.backtrace.join("\n") }
    end
  end
end
