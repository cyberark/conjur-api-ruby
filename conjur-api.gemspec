# -*- encoding: utf-8 -*-
require File.expand_path('../lib/conjur-api/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rafa\305\202 Rzepecki","Kevin Gilpin"]
  gem.email         = ["divided.mind@gmail.com","kgilpin@conjur.net"]
  gem.description   = %q{Conjur API}
  gem.summary       = %q{Conjur API}
  gem.homepage      = ""
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\) + Dir['build_number']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "conjur-api"
  gem.require_paths = ["lib"]
  gem.version       = Conjur::API::VERSION
  
  gem.add_dependency 'rest-client'
  gem.add_dependency 'activesupport'
  
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'spork'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'ci_reporter'
  gem.add_development_dependency 'simplecov'
end
