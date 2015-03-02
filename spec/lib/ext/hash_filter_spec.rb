require 'happy'

RSpec.describe '#filter' do
  it 'works' do
    expect({}.filter).to eq({})
  end

  it 'works' do
    expect({ a:1 }.filter).to eq({})
  end

  it 'works' do
    expect({ a:1 }.filter(:a)).to eq(a:1)
  end

  it 'works' do
    expect({ a:1, b:2 }.filter(:a, :b)).to eq(a:1, b:2)
  end

  it 'works' do
    expect({ a:1, b:2, c:3 }.filter(:a, :b)).to eq(a:1, b:2)
  end
end
