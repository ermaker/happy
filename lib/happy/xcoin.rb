require 'phantomjs/poltergeist'

module Happy
  module XCoin
    module Market
      def self.extended(mod)
        [
          [Happy::Currency::KRW_X, Happy::Currency::BTC_X]
        ].each do |base,counter|
          mod.proc_market[[base, counter]] = mod.method(:market_xcoin)
        end
      end

      Capybara.current_driver = :poltergeist
      include Capybara::DSL

      def market_xcoin(_base, _counter)
        # TODO: ensure base and counter
        visit 'http://www.xcoin.co.kr'
        Nokogiri.HTML(page.body).xpath("//tr[@class='sell']")
          .map do |tr|
          [
            Amount.new(tr.xpath('./td[2]').text.gsub(',', ''), 'KRW_X'),
            Amount.new(tr.xpath('./td[3]').text, 'BTC_X')
          ]
        end.reverse.map do |price,amount|
          {
            'price' => price,
            'taker_gets_funded' => amount,
            'taker_pays_funded' => price * amount
          }
        end
      rescue
        retry
      end
    end
  end
end
