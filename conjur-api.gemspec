# -*- encoding: utf-8 -*-
require File.expand_path('../lib/conjur-api/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rafal Rzepecki","Kevin Gilpin"]
  gem.email         = ["rafal@conjur.net","kgilpin@conjur.net"]
  gem.description   = %q{Conjur API}
  gem.summary       = %q{Conjur API}
  gem.homepage      = "https://github.com/conjurinc/api-ruby/"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\) + Dir['build_number']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "conjur-api"
  gem.require_paths = ["lib"]
  gem.version       = Conjur::API::VERSION

  gem.required_ruby_version = '>= 1.9'

  
  gem.add_dependency 'rest-client', '= 1.6.7' # with newer versions adding certificates to OpenSSL does not work
  gem.add_dependency 'activesupport'
  
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'spork'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'ci_reporter_rspec'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'io-grab'
  gem.add_development_dependency 'rdoc'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'redcarpet'
  gem.add_development_dependency 'timecop'
end
