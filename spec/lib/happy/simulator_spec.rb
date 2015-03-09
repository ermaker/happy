require 'happy'

RSpec.describe Happy::Simulator do
  describe Happy::Simulator::Balance do
    subject do
      Happy::Worker.new.tap do |worker|
        worker.extend(Happy::Worker::Balance)
      end
    end

    it 'works' do
      KRW_R = Happy::Currency::KRW_R
      expect(subject.balance(KRW_R))
        .to be_empty
      subject.extend(described_class)
      expect(subject.balance(KRW_R))
        .to be_empty
    end
  end
end
