module Happy
  class Job < JobBase
    def initialize
      super
      @local = {
        'class' => {},
        'balances' => AmountHash.new
      }
    end

    def push(*args)
      super('args' => args)
    end

    def push_detail(*)
      super
    end

    def class_of(job)
      return job['class'] if job.key?('class')
      @local['class']
        .find { |k,_| k == job['args'] }
        .last
    end

    def from_jsonify(jsonify)
      super
      @local['balances'] = AmountHash.new.apply(@local['balances'])
      self
    end
  end
end
