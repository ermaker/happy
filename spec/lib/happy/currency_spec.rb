require 'happy'

RSpec.describe Happy::Currency do
  let(:hashed_currency) do
    { 'currency' => 'XRP', 'counterparty' => '' }
  end

  let!(:currency) do
    described_class[hashed_currency]
  end

  it 'works' do
    expect(currency).to eq(currency)
  end

  it 'works' do
    expect(currency).to be_same_currency(currency)
  end

  it 'works' do
    expect(currency.with('1')).to eq(Happy::Amount.new('1', currency))
  end
end
