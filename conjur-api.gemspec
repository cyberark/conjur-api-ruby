# -*- encoding: utf-8 -*-
require File.expand_path('../lib/conjur-api/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rafa\305\202 Rzepecki","Kevin Gilpin"]
  gem.email         = ["divided.mind@gmail.com","kevin.gilpin@inscitiv.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "conjur-api"
  gem.require_paths = ["lib"]
  gem.version       = Conjur::API::VERSION
  
  gem.add_runtime_dependency 'rest-client'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'vcr'
  gem.add_development_dependency 'webmock'
end
