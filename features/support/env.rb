require 'simplecov'

SimpleCov.start

require 'json_spec/cucumber'
require 'conjur/api'

puts "env.rb ENV['CONJUR_APPLIANCE_URL']: #{ENV['CONJUR_APPLIANCE_URL']}"
puts "env.rb ENV['CONJUR_AUTHN_API_KEY']: #{ENV['CONJUR_AUTHN_API_KEY']}"
Conjur.configuration.appliance_url = ENV['CONJUR_APPLIANCE_URL'] || 'http://localhost/api/v6'
Conjur.configuration.account = ENV['CONJUR_ACCOUNT'] || 'cucumber'

$username = ENV['CONJUR_AUTHN_LOGIN'] || 'admin'
$password = ENV['CONJUR_AUTHN_API_KEY'] || 'secret'

puts '#######################################'
puts "$username: #{$username}"
puts "$password: #{$password}"
puts "Conjur.configuration.appliance_url: #{Conjur.configuration.appliance_url}"
puts "Conjur.configuration.account: #{Conjur.configuration.account}"
puts '#######################################'

$api_key = Conjur::API.login $username, $password
$conjur = Conjur::API.new_from_key $username, $api_key
