require 'happy'

class Job < Happy::JobBase
  def push(klass, *args)
    super(
      'class' => klass,
      'args' => args
    )
  end

  def class_of(job)
    job['class']
  end
end

class WorkerTest
  include Sidekiq::Worker

  def perform
  end
end

RSpec.describe Job do
  it '#push works' do
    subject.push(WorkerTest)
  end

  it '#to_jsonify and #from_jsonify works' do
    subject.push(WorkerTest)
    subject2 = described_class.from_jsonify(subject.to_jsonify)
    expect(subject2.to_jsonify).to eq(subject.to_jsonify)
  end

  describe '#work' do
    it 'works with class' do
      expect(Sidekiq::Client).to receive(:push)
      subject.push(WorkerTest)
      subject.work
    end

    it 'works with string' do
      expect(Sidekiq::Client).to receive(:push)
      subject.push(WorkerTest.to_s)
      subject.work
    end

    describe 'with split' do
      it 'works' do
        expect(Sidekiq::Client).to receive(:push).twice
        subject.jobs =[
          [{ 'class' => WorkerTest, 'args' => [] }],
          { 'class' => WorkerTest, 'args' => [] }
        ]
        subject.work
      end

      it 'works' do
        expect(Sidekiq::Client).to receive(:push)
        subject.jobs =[
          [],
          { 'class' => WorkerTest, 'args' => [] }
        ]
        subject.work
      end

      it 'works' do
        expect(Sidekiq::Client).to receive(:push)
        subject.jobs =[
          [{ 'class' => WorkerTest, 'args' => [] }]
        ]
        subject.work
      end

      it 'works' do
        expect(Sidekiq::Client).to receive(:push).twice
        subject.jobs =[
          [{ 'class' => WorkerTest, 'args' => [] }],
          [{ 'class' => WorkerTest, 'args' => [] }]
        ]
        subject.work
      end

      it 'works' do
        expect(Sidekiq::Client).to receive(:push).exactly(3).times
        subject.jobs =[
          [{ 'class' => WorkerTest, 'args' => [] }],
          [{ 'class' => WorkerTest, 'args' => [] }],
          { 'class' => WorkerTest, 'args' => [] }
        ]
        subject.work
      end

      it 'works' do
        expect(Sidekiq::Client).to receive(:push)
        subject.jobs =[
          { 'class' => WorkerTest, 'args' => [] },
          [{ 'class' => WorkerTest, 'args' => [] }]
        ]
        subject.work
      end
    end
  end
end
