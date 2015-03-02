require 'happy'

RSpec.describe '#to_jsonify' do
  let(:amount) do
    Happy::Amount[{ 'value' => '1', 'currency' => 'XRP', 'counterparty' => '' }]
  end

  let(:amount_jsonified) do
    { 'value' => { 'value' => 1.0, 'raw' => '0.1E1' },
      'currency' => 'XRP', 'counterparty' => '' }
  end

  let(:currency) do
    Happy::Currency[{ 'currency' => 'XRP', 'counterparty' => '' }]
  end

  it 'works' do
    object = Object.new
    expect(object.to_jsonify).to eq(object)
  end

  it 'works' do
    expect({}.to_jsonify).to eq({})
    expect({ a:1 }.to_jsonify).to eq(a:1)
  end

  it 'works' do
    expect(BigDecimal.new('1').to_jsonify).to eq('value' => 1.0, 'raw' => '0.1E1')
  end

  it 'works' do
    time = Time.now
    expect(time.to_jsonify).to eq(time.utc.strftime('%FT%T.%L%z'))
  end

  it 'works' do
    expect(amount.to_jsonify).to eq(amount_jsonified)
  end

  it 'works' do
    expect(currency.to_jsonify).to eq(currency)
  end

  it 'works' do
    json = { 'price' => amount }
    expect(json.to_jsonify).to eq('price' => amount_jsonified)
  end

  it 'works' do
    json = [amount]
    expect(json.to_jsonify).to eq([amount_jsonified])
  end
end
