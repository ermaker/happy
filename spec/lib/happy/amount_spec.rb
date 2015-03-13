require 'happy'

RSpec.describe Happy::Amount do
  let!(:amount) do
    described_class[
      { 'value' => '1', 'currency' => 'XRP', 'counterparty' => '' }
    ]
  end

  let!(:amount2) do
    described_class[
      { 'value' => '1.1', 'currency' => 'XRP', 'counterparty' => '' }
    ]
  end

  let!(:jsonified_amount) do
    described_class[
      { 'value' => { 'value' => 1.0, 'raw' => '0.1E1' }, 'currency' => 'XRP', 'counterparty' => '' }
    ]
  end

  it 'works' do
    expect(jsonified_amount).to eq(amount)
  end

  it 'works' do
    expect(1 * amount).to eq(amount)
    expect(amount * 1).to eq(amount)
  end

  it 'works' do
    expect(amount * '1').to eq(amount)
  end

  it 'works' do
    expect(amount / '1').to eq(amount)
  end

  it 'does not work' do
    expect do
      expect('1' * amount).to eq(amount)
    end.to raise_error
    expect do
      expect('1' / amount).to eq(amount)
    end.to raise_error
  end

  it 'works' do
    expect(1 / amount).to eq(amount)
    expect(amount / 1).to eq(amount)
  end

  it 'works' do
    expect(described_class['value' => '1']['value']).to eq(BigDecimal.new('1'))
    expect(described_class['value' => 1]['value']).to eq(BigDecimal.new('1'))
    expect(described_class['value' => BigDecimal.new('1')]['value']).to eq(BigDecimal.new('1'))
  end
end
