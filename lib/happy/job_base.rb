module Happy
  class JobBase
    attr_accessor :local

    def initialize
      @jobs = []
    end

    def push(job)
      @jobs.push(job)
    end

    def work
      return if @jobs.empty?
      job = @jobs.shift
      klass = class_of(job)
      job =
        { 'class' => klass }.merge(
          klass.get_sidekiq_options
        ).merge(job)
      job['args'].unshift(to_jsonify)
      Sidekiq::Client.push(job)
    end

    def to_jsonify
      Hash[
        instance_variables.map do |k|
          [k, instance_variable_get(k).to_jsonify]
        end + [['class', self.class]]
      ]
    end

    def from_jsonify(jsonify)
      jsonify.each do |k,v|
        instance_variable_set(k, v.to_objectify)
      end
      self
    end

    def self.from_jsonify(jsonify)
      klass = jsonify.delete('class').constantize
      klass.new.from_jsonify(jsonify)
    end
  end
end
