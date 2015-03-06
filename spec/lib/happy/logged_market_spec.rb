require 'happy'

RSpec.describe Happy::LoggedMarket do
  it '#lower works' do
    time = Time.parse('2015-03-06T13:40:01.000Z')
    expected = Time.parse('2015-03-06T13:40:00.000Z')
    expect(subject.lower(time)).to eq(expected)
  end

  describe '#upper' do
    it 'works' do
      time = Time.parse('2015-03-06T13:40:01.000Z')
      expected = Time.parse('2015-03-06T13:41:00.000Z')
      expect(subject.upper(time)).to eq(expected)
    end

    it 'works' do
      time = Time.parse('2015-03-06T13:59:00.000Z')
      expected = Time.parse('2015-03-06T14:00:00.000Z')
      expect(subject.upper(time)).to eq(expected)
    end
  end
end
