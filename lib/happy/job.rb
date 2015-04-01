module Happy
  class Job < JobBase
    def initialize
      super
      @local = {
        'initial_balances' => AmountHash.new,
        'balances' => AmountHash.new
      }
    end

    def initial_balances=(balances)
      @local['initial_balances'] =
        AmountHash.new.apply(balances)
      @local['balances'] =
        AmountHash.new.apply(balances)
    end

    def initial_balances
      @local['initial_balances']
    end

    def balances
      @local['balances']
    end

    def path=(path)
      @local['path'] = path
    end

    def path
      @local['path']
    end

    def class_of(job)
      job['class']
    end

    def from_jsonify(jsonify)
      super
      @local['initial_balances'] =
        AmountHash.new.apply(@local['initial_balances'])
      @local['balances'] = AmountHash.new.apply(@local['balances'])
      self
    end
  end
end
