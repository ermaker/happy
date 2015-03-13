require 'happy'

RSpec.describe '#currency' do
  let!(:amount) do
    Happy::Amount[
      { 'value' => '1', 'currency' => 'XRP', 'counterparty' => '' }
    ]
  end

  it 'works' do
    expect('1'.currency('XRP')).to eq(amount)
    expect(1.currency('XRP')).to eq(amount)
    expect(BigDecimal.new('1').currency('XRP')).to eq(amount)
  end
end
