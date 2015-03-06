require 'happy'

RSpec.describe '#to_objectify' do
  let(:amount) do
    { 'value' => '1', 'currency' => 'XRP', 'counterparty' => '' }
  end

  let(:hashed_amount) do
    { 'value' => { 'value' => 1.0, 'raw' => '0.1E1' }, 'currency' => 'XRP', 'counterparty' => '' }
  end

  let(:currency) do
    { 'currency' => 'XRP', 'counterparty' => '' }
  end

  it 'works' do
    object = Object.new
    expect(object.to_objectify).to eq(object)
  end

  it 'works' do
    expect({}.to_objectify).to eq({})
    expect({ a:1 }.to_objectify).to eq(a:1)
  end

  it 'works' do
    expect(amount.to_objectify).to eq(Happy::Amount[amount])
  end

  it 'works' do
    expect(hashed_amount.to_objectify).to eq(Happy::Amount[amount])
  end

  it 'works' do
    expect(currency.to_objectify).to eq(Happy::Currency[currency])
  end

  it 'works' do
    json = { 'price' => amount }
    expect(json.to_objectify).to eq('price' => Happy::Amount[amount])
  end

  it 'works' do
    json = [amount]
    expect(json.to_objectify).to eq([Happy::Amount[amount]])
  end

  it 'works' do
    json = [{ 'price' => amount }]
    expect(json.to_objectify).to eq([{ 'price' => Happy::Amount[amount] }])
  end
end
