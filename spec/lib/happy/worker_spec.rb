require 'happy'

RSpec.describe Happy::Worker do
  describe Happy::Worker::Balance do
    subject do
      Happy::Worker.new.tap do |worker|
        worker.extend(described_class)
      end
    end

    let!(:amount_hash) do
      Happy::AmountHash.new.tap do |ah|
        ah.apply(Happy::Amount.new('4225', Happy::Currency::KRW_R))
      end
    end

    let(:balance_test) do
      Module.new do
        def self.extended(mod)
          mod.proc_balance[Happy::Currency::KRW_R] = proc do
            Happy::AmountHash.new.tap do |ah|
              ah.apply(Happy::Amount.new('4225', Happy::Currency::KRW_R))
            end
          end
        end
      end
    end

    it 'works' do
      expect(subject.balance(Happy::Currency::KRW_R)).to be_empty
      subject.extend(balance_test)
      expect(subject.balance(Happy::Currency::KRW_R)).to eq(amount_hash)
    end
  end

  describe Happy::Worker::Market do
    subject do
      Happy::Worker.new.tap do |worker|
        worker.extend(described_class)
      end
    end

    it 'works' do
      expect do
        subject.market(Happy::Currency::KRW_R, Happy::Currency::KRW_R)
      end.to raise_error(/^No market defined for \S+ -> \S+$/)
    end
  end

  describe Happy::Worker::Exchange do
    subject do
      Happy::Worker.new.tap do |worker|
        worker.extend(described_class)
      end
    end

    it 'works' do
      expect do
        subject.exchange(
          Happy::Amount.new('0', Happy::Currency::KRW_R),
          Happy::Currency::KRW_R
        )
      end.to raise_error(/^No exchange defined for \S+ -> \S+$/)
    end
  end
end
