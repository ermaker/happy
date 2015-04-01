require 'time'

module Happy
  class Job < JobBase
    def initialize
      super
      @local = {
        'initial_balances' => AmountHash.new,
        'balances' => AmountHash.new
      }
      start_time!
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

    def start_time!
      @local['start_time'] = Time.now
    end

    def start_time
      @local['start_time']
    end

    def class_of(job)
      job['class']
    end

    def from_jsonify(jsonify)
      super
      @local['initial_balances'] =
        AmountHash.new.apply(@local['initial_balances'])
      @local['balances'] = AmountHash.new.apply(@local['balances'])
      @local['start_time'] =
        Time.parse(@local['start_time']) if @local.key?('start_time')
      self
    end
  end
end
