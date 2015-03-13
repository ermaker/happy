require 'happy'

RSpec.describe Happy::AmountHash do
  let!(:zero_amount) do
    0.currency('XRP')
  end

  let!(:amount) do
    1.currency('XRP')
  end

  it 'works' do
    expect(subject.apply(zero_amount)).to be_empty
  end

  it 'works' do
    expect(subject.apply(amount)).to eq(amount.currency => amount)
  end

  it 'works' do
    expect(subject.apply(amount, amount)).to eq(amount.currency => amount * 2)
  end

  it 'works' do
    expect(subject.apply([amount])).to eq(amount.currency => amount)
  end

  it 'works' do
    expect(subject.apply([[amount]])).to eq(amount.currency => amount)
  end

  it 'works' do
    expect(subject.apply(amount.currency => amount)).to eq(amount.currency => amount)
  end

  it 'works' do
    expect(subject.apply([{ amount.currency => amount }])).to eq(amount.currency => amount)
  end

  it 'works' do
    expect(subject.apply(amount => amount)).to eq(amount.currency => amount * 2)
  end
end
