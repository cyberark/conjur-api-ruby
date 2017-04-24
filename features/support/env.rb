require 'conjur/api'
require 'json_spec/cucumber'

Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://localhost/api/v6'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'

$username = ENV['CONJUR_AUTHN_LOGIN'] || 'admin'
$password = ENV['CONJUR_AUTHN_API_KEY'] || 'secret'

$api_key = Conjur::API.login $username, $password
$conjur = Conjur::API.new_from_key $username, $api_key
