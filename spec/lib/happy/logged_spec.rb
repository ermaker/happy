require 'happy'

RSpec.describe Happy::Logged::Market do
  subject do
    Happy::Worker.new.tap do |worker|
      worker.extend(Happy::Worker::Market)
      worker.extend(described_class)
    end
  end

  it '#market_logged_lower works' do
    subject.time = Time.parse('2015-03-06T13:40:01.000Z')
    expected = Time.parse('2015-03-06T13:10:00.000Z')
    expect(subject.market_logged_lower).to eq(expected)
  end

  describe '#market_logged_upper' do
    it 'works' do
      subject.time = Time.parse('2015-03-06T13:40:01.000Z')
      expected = Time.parse('2015-03-06T13:41:00.000Z')
      expect(subject.market_logged_upper).to eq(expected)
    end

    it 'works' do
      subject.time = Time.parse('2015-03-06T13:59:00.000Z')
      expected = Time.parse('2015-03-06T14:00:00.000Z')
      expect(subject.market_logged_upper).to eq(expected)
    end
  end
end
