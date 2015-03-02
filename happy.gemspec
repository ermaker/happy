# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'happy/version'

Gem::Specification.new do |spec|
  spec.name          = "happy"
  spec.version       = Happy::VERSION
  spec.authors       = ["TODO: Write your name"]
  spec.email         = ["TODO: Write your email address"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'dotenv'
  spec.add_dependency 'thor'
  spec.add_dependency 'mshard'
  spec.add_dependency 'pretty_backtrace'
  spec.add_dependency 'httparty'
  spec.add_dependency 'poltergeist'
  spec.add_dependency 'phantomjs'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'mail'
  spec.add_dependency 'elasticsearch'
  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'pry'
end
