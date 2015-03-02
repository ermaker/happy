require 'httparty'

module Happy
  class XRP
    attr_accessor :address, :bids

    def initialize(address)
      @bids = Hash.new do |hash, (base, counter)|
        hash[[base, counter]] =
          order_book(base, counter)['bids']
      end
      @address = address
    end

    def order_book(base, counter)
      limit = 200
      response = HTTParty.get(
        "https://api.ripple.com/v1/accounts/#{@address}/order_book/#{base}/#{counter}",
        query: { limit: limit })
                 .parsed_response
      fail response.inspect unless response['success']
      response
    end

    BID_WHITE_LIST = %w(price taker_gets_funded taker_pays_funded)

    def market(base, counter)
      order_book = order_book(base, counter)
      order_book['bids']
        .map { |bid| bid.filter(*BID_WHITE_LIST) }
        .to_objectify
    end

    def exchange_xrp(amount, counter)
      rest_amount = amount
      base = amount.currency
      price = Amount.new('0', counter)

      bid_idx = -1
      loop do
        bid = @bids[[base, counter]][bid_idx += 1]
        pay = Amount[bid['taker_pays_funded']]
        if rest_amount >= pay
          rest_amount -= pay
          price += Amount[bid['taker_gets_funded']]
        else
          price += Amount[bid['taker_gets_funded']] * rest_amount / pay
          break
        end
      end
      result = AmountHash.new
      result.apply(-amount)
      result.apply(price)
      result.apply(-Amount::XRP_FEE)
      result
    end
  end
end

__END__
require 'phantomjs/poltergeist'
Capybara.current_driver = :poltergeist

class Simulator
  attr_accessor :amounts, :address, :bids, :commands

  def initialize(address)
    @bids = Hash.new do |hash, (base, counter)|
      hash[[base, counter]] =
        order_book(base, counter)['bids']
    end
    @address = address
    @amounts = AmountHash.new
    @commands = []
  end

  def order_book(base, counter)
    limit = 200
    response = HTTParty.get(
      "https://api.ripple.com/v1/accounts/#{@address}/order_book/#{base}/#{counter}",
      query: { limit: limit })
               .parsed_response
    fail response.inspect unless response['success']
    response
  end

  def deposit_xcoin(amount)
    result = AmountHash.new
    result.apply(-amount)
    result.apply(Amount.new('1', 'KRW_X') * amount)
    @amounts.apply_all(result)
    result
  end

  def krw_r2krw_x
    amount = @amounts[Currency::KRW_R]
    @commands << "KRW_R to KRW_X: #{amount}"
    deposit_xcoin(amount)
  end

  include Capybara::DSL

  def xcoin_bids_impl
    visit 'http://www.xcoin.co.kr'
    sell = Nokogiri.HTML(page.body).xpath(
      "//tr[@class='sell']")
    sell.reverse.map do |tr|
      [
        tr.xpath('./td[2]').text.gsub(',', ''),
        tr.xpath('./td[3]').text
      ]
    end
  end

  attr_writer :xcoin_bids
  def xcoin_bids
    @xcoin_bids ||= xcoin_bids_impl
  end

  def xxx(counter, amount)
    rest_amount = amount
    price = Amount.new('0', counter)
    bid_idx = -1
    loop do
      bid = xcoin_bids[bid_idx += 1]
      price_ = Amount.new(bid[1], counter.currency)
      pay = Amount.new(bid[0], amount.currency) * price_
      if rest_amount >= pay
        rest_amount -= pay
        price += price_
      else
        price += price_ * rest_amount / pay
        break
      end
    end
    price
  end

  def exchange_xcoin(_base, counter, amount)
    result = AmountHash.new
    result.apply(-amount)
    amount_counter = xxx(counter, amount)
    result.apply(
      Amount.new(Amount::XCOIN_ANTI_FEE_RATIO, counter) *
      amount_counter)
    @amounts.apply_all(result)
    result
  end

  def krw_x2btc_x
    amount = @amounts[Currency::KRW_X]
    @commands << "KRW_X to BTC_X: #{amount} / #{xxx(Currency::BTC_X, amount)}"
    exchange_xcoin(
      Currency::KRW_X,
      Currency::BTC_X,
      amount)
  end

  def exchange_btc(_base, counter, amount)
    result = AmountHash.new
    result.apply(-amount)
    result.apply(Amount.new('1', counter) * amount)
    result.apply(-Amount.new(Amount::BTC_FEE, counter))
    @amounts.apply_all(result)
    result
  end

  def btc_x2btc_btcxrp
    amount = @amounts[Currency::BTC_X]
    @commands << "BTC_X to BTC_BTCXRP: #{amount}"
    exchange_btc(
      Currency::BTC_X,
      Currency::BTC_BTCXRP,
      amount)
  end

  def btc2xrp_gateway(amount)
    result = AmountHash.new
    result.apply(-amount)
    result.apply(Amount.new('1', 'BTC_P') * amount)
    @amounts.apply_all(result)
    result
  end

  def btc_btcxrp2btc_p
    amount = @amounts[Currency::BTC_BTCXRP]
    @commands << "BTC_BTCXRP to BTC_P: #{amount}"
    btc2xrp_gateway(amount)
  end

  def exchange_xrp(base, counter, amount)
    whole_amount = rest_amount = amount
    price = Amount.new('0', counter)

    bid_idx = -1
    loop do
      bid = @bids[[base, counter]][bid_idx += 1]
      pay = Amount[bid['taker_pays_funded']]
      if rest_amount >= pay
        rest_amount -= pay
        price += Amount[bid['taker_gets_funded']]
      else
        price += Amount[bid['taker_gets_funded']] * rest_amount / pay
        break
      end
    end
    result = AmountHash.new
    result.apply(-whole_amount)
    result.apply(price)
    result.apply(-Amount::XRP_FEE)
    @amounts.apply_all(result)
    result
  end

  def btc_p2xrp
    amount = @amounts[Currency::BTC_P]
    @commands << "BTC_P to XRP: #{amount}"
    exchange_xrp(Currency::BTC_P, Currency::XRP, amount)
  end

  def xrp2krw_p
    amount = @amounts[Currency::XRP] -
             Amount::XRP_FEE - Amount::XRP_FEE
    @commands << "XRP to KRW_P: #{amount}"
    exchange_xrp(Currency::XRP, Currency::KRW_P, amount)
  end

  def exchange_paxmoneta(amount)
    fail unless amount.same_currency? Currency::KRW_P

    result = AmountHash.new
    result.apply(-amount)
    result.apply(-Amount::XRP_FEE)
    result.apply(
      Amount.new(Amount::PAXMONETA_ANTI_FEE_RATIO, 'KRW_R') *
      amount)
    @amounts.apply_all(result)
    result
  end

  def krw_p2krw_r
    amount = @amounts[Currency::KRW_P]
    @commands << "KRW_P to KRW_R: #{amount}"
    exchange_paxmoneta(amount)
  end
end
