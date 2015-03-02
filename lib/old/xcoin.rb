require 'phantomjs/poltergeist'
Capybara.current_driver = :poltergeist

class XCoin
  def initialize(user, password, password2)
    @user = user
    @password = password
    @password2 = password2
  end

  include Capybara::DSL

  def not_found(*args)
    find *args
    return false
  rescue Capybara::ElementNotFound
    return true
  rescue
    return false
  end

  def ensure_login
    $logger.debug { 'ensure_login' }
    visit 'https://www.xcoin.co.kr/u1/US101'
    if not_found(:css, '.gnb_s1') && find(:css, '.gnb')
      $logger.debug { 'already logged in' }
      return
    end
    $logger.debug { 'Fill username and password' }
    fill_in 'j_username', with: @user
    fill_in 'j_password', with: @password
    $logger.debug { 'Submit' }
    find(:xpath, '//p[@class="btn_org"]').click
    $logger.debug { 'ensure_login finished' }
  rescue => e
    $logger.warn { e.class }
    $logger.warn { e }
    $logger.warn { e.backtrace.join("\n") }
    retry
  end

  def status
    $logger.debug { 'status' }
    loop do
      $logger.debug { 'loop' }
      visit 'https://www.xcoin.co.kr/u2/US202'
      $logger.debug { 'Parse' }
      stat = find(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr[last()]/td[7]').text
      break if stat == '완료'
      sleep 2
    end
    krw_x = find(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr[last()]/td[4]').text
    btc_x = find(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr[last()]/td[5]').text
    btc_x_fee = find(:xpath, '//table[@class="g_table_list g_table_list_s1"]//tr[last()]/td[6]').text
    krw_x = Amount.new(krw_x.gsub(',', ''), 'KRW_X')
    btc_x = Amount.new(btc_x, 'BTC_X')
    btc_x_fee = Amount.new(btc_x_fee, 'BTC_X')
    btc_x -= btc_x_fee
    $logger.debug { 'status finished' }
    return [krw_x, btc_x]
  rescue => e
    $logger.warn { e.class }
    $logger.warn { e }
    $logger.warn { e.backtrace.join("\n") }
    retry
  end

  def buy(btc_x)
    $logger.debug { 'buy' }
    visit 'https://www.xcoin.co.kr/u2/US202'
    $logger.debug { 'Fill' }
    fill_in 'traPwNo', with: @password2
    check 'gen'
    fill_in 'btcQty', with: btc_x['value'].to_s('F')
    check 'auto_price'
    find(:xpath, '//p[@class="btn_org"]').click
    find(:css, '._wModal_btn_yes').click
    $logger.debug { 'buy finished' }
  rescue => e
    $logger.warn { e.class }
    $logger.warn { e }
    $logger.warn { e.backtrace.join("\n") }
    retry
  end

  def send_(destination_address, btc_x)
    $logger.debug { 'send_' }
    visit 'https://www.xcoin.co.kr/u3/US302'
    # btc_value = find(:xpath, '//table[@class="g_table"]/tbody/tr[1]/td').text[/^(.*?) BTC$/,1]
    btc_value = btc_x['value'].to_s('F')
    $logger.debug { "btc_value: #{btc_value}" }
    fill_in 'btcOutAmt', with: btc_value
    fill_in 'btcOutAdd', with: destination_address
    fill_in 'traPwNo', with: @password2
    $logger.debug { 'xcoin_sms_validation_code set' }
    MShard::MShard.new.set(
      id: 'xcoin_sms_validation_code',
      contents: '')
    find(:xpath, '//div[text()="인증요청"]').click
    find(:css, '._wModal_btn_yes').click
    $logger.debug { 'xcoin_sms_validation_code loop start' }
    sms = loop do
      sleep 1
      begin
        $logger.debug { 'xcoin_sms_validation_code get' }
        result = MShard::MShard.new.get('xcoin_sms_validation_code')
        $logger.debug { "xcoin_sms_validation_code get: #{result.inspect}" }
        break result unless result.empty?
      rescue => e
        $logger.warn { e.class }
        $logger.warn { e }
        $logger.warn { e.backtrace.join("\n") }
      end
    end
    $logger.debug { 'xcoin_sms_validation_code loop end' }
    fill_in 'smsKeyTmp', with: sms
    find(:xpath, '//p[@class="btn_org"]').click
    find(:css, '._wModal_btn_yes').click
    $logger.debug { 'send_ finished' }
  rescue => e
    $logger.warn { e.class }
    $logger.warn { e }
    $logger.warn { e.backtrace.join("\n") }
    retry
  end
end
