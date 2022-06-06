# -*- encoding: utf-8 -*-
require File.expand_path('../lib/conjur-api/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["CyberArk Maintainers"]
  gem.email         = ["conj_maintainers@cyberark.com"]
  gem.description   = %q{Conjur API}
  gem.summary       = %q{Conjur API}
  gem.homepage      = "https://github.com/cyberark/conjur-api-ruby/"
  gem.license       = "Apache-2.0"

  gem.files         = `git ls-files`.split($\).append("VERSION") + Dir['build_number']
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "conjur-api"
  gem.require_paths = ["lib"]
  gem.version       = Conjur::API::VERSION

  gem.required_ruby_version = '>= 1.9'

  # Filter out development only executables
  gem.executables -= %w{parse-changelog.sh}

  gem.add_dependency 'rest-client'
  gem.add_dependency 'activesupport', '>= 4.2'
  gem.add_dependency 'addressable', '~> 2.0'

  gem.add_development_dependency 'rake', '>= 12.3.3'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'rspec-expectations', '~> 3.4'
  gem.add_development_dependency 'json_spec'
  gem.add_development_dependency 'cucumber', '~> 2.99'
  gem.add_development_dependency 'ci_reporter_rspec'
  gem.add_development_dependency 'simplecov', '~> 0.17', '< 0.18'
  gem.add_development_dependency 'io-grab'
  gem.add_development_dependency 'rdoc'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'fakefs'
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'nokogiri'
end
