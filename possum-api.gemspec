# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'possum/version'

Gem::Specification.new do |spec|
  spec.name          = "possum-api"
  spec.version       = Possum::VERSION
  spec.authors       = ["Rafał Rzepecki"]
  spec.email         = ["rafal@conjur.net"]

  spec.summary       = %q{Possum API library}
  spec.description   = %q{A basic library to access Possum service.}
  spec.homepage      = "https://github.com/conjurinc/possum-api"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "webmock", "~> 2.1"
  spec.add_dependency "faraday", "~> 0.9"
end
