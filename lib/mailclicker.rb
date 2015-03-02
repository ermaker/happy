# encoding: utf-8

require 'env'
require 'xcoin'
require 'mail'
require 'nokogiri'

Mail.defaults do
	retriever_method :imap,
		address: 'imap.gmail.com',
		port: 993,
		user_name: 'ermaker.order@gmail.com',
		password: 'g00dm0rning',
		enable_ssl: true
end

def click mail
	$logger.debug { 'click' }
	body = mail.parts.find { |part| part.content_type =~ %r{^text/html} }.body.to_s
	html = Nokogiri.HTML(body)
	link = html.xpath('//a[text()="여기를 클릭하세요!"]/@href').text
	$logger.debug { "link: #{link}" }
	user = ENV['XCOIN_USER']
	password = ENV['XCOIN_PASSWORD']
	password2 = ENV['XCOIN_PASSWORD2']
	begin
		xcoin = XCoin.new(user, password, password2)
		xcoin.ensure_login
		xcoin.visit link
	rescue => e
		$logger.warn { e.class }
		$logger.warn { e }
		$logger.warn { e.backtrace.join("\n") }
		MShard::MShard.new.set(
			pushbullet: true,
			channel_tag: 'morder_process',
			type: 'link',
			title: e.class.to_s,
			body: link,
			contents: <<-CONTENTS,
<pre>
#{e.class}
#{e}
#{e.backtrace.join("\n")}
</pre>
			CONTENTS
		)

		retry
	end
	#MShard::MShard.new.set(
	#	pushbullet: true,
	#	channel_tag: 'morder_process',
	#	type: 'note',
	#	title: 'Link clicked',
	#	body: link
	#)
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

def put mail
	$logger.debug { 'put' }
	if matched = mail.body.to_s.match(/XCOIN Verification Code : (\d+)/)
		$logger.debug { "xcoin_sms_validation_code: #{matched[1]}" }
		MShard::MShard.new.set(
			id: 'xcoin_sms_validation_code',
			contents: matched[1]
		)
	end
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

def check
	$logger.debug { 'check' }
	Mail.find(delete_after_find: true).each do |mail|
		$logger.debug { "mail: #{mail.subject}" }
		click mail if mail.subject =~ /출금요청/
		put mail if mail.subject =~ /Forwarded Message from /
	end
	$logger.debug { 'check finished' }
end

loop do
	begin
		check
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
	sleep 5
end
