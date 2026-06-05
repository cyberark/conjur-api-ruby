require 'simplecov'
require 'nokogiri'
require 'simplecov-cobertura'

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter


SimpleCov.start do
  command_name "#{ENV['RUBY_VERSION']}"
end

require 'json_spec/cucumber'
require 'conjur/api'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://localhost/api/v6'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'
Conjur.configuration.authn_local_socket = "/run/authn-local/.socket"

$username = ENV['CONJUR_AUTHN_LOGIN'] || 'admin'
$api_key = (ENV['CONJUR_AUTHN_API_KEY'] && !ENV['CONJUR_AUTHN_API_KEY'].empty?) \
           ? ENV['CONJUR_AUTHN_API_KEY'] \
           : Conjur::API.login($username, 'secret')
$conjur = Conjur::API.new_from_key $username, $api_key
