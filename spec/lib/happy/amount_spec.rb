require 'happy'

RSpec.describe Happy::Amount do
  let(:amount) do
    { 'value' => '1', 'currency' => 'XRP', 'counterparty' => '' }
  end

  let(:hashed_amount) do
    { 'value' => { 'value' => 1.0, 'raw' => '0.1E1' }, 'currency' => 'XRP', 'counterparty' => '' }
  end

  it 'works' do
    expect(described_class[hashed_amount]).to eq(described_class[amount])
  end
end
