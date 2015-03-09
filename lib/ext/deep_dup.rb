require 'yaml'

class Object
  def deep_dup
    YAML.load(to_yaml)
  end
end
