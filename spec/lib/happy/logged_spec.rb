require 'happy'

RSpec.describe Happy::Logged do
  describe Happy::Logged::Market do
    subject do
      Happy::Worker.new.tap do |worker|
        worker.extend(Happy::Worker::Market)
      end
    end

    it 'works' do
      subject.extend(described_class)
      subject.time = Time.now - 60 * 60
      expect(
        subject.market(
          Happy::Currency::KRW_X,
          Happy::Currency::BTC_X
        )
      ).to satisfy { |actual| actual.size == 7 }
      expect(
        subject.market(
          Happy::Currency::BTC_P,
          Happy::Currency::XRP
        )
      ).to satisfy { |actual| actual.size == 199 }
    end
  end
end
