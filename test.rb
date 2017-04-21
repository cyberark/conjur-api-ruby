require 'conjur-api'

Conjur.configuration.appliance_url = 'http://localhost/api/v6'
Conjur.configuration.account = 'cucumber'

api_key = Conjur::API.login 'admin', 'secret'
puts api_key
api_key = Conjur::API.rotate_api_key 'admin', api_key
puts "Rotated: " + api_key

api = Conjur::API.new_from_key 'admin', api_key

puts api.token

begin
  Conjur::API.new_from_key('admin', api_key, account: 'foobar').token
  raise "Expected authentication failure!"
rescue RestClient::Unauthorized
  puts "Authentication to foreign account failed, as expected"
end

policy = <<-POLICY
- !group security_admin

- !policy
  id: myapp
  body:
  - !layer
  
  - !host-factory
    layers: [ !layer ]
    
- !host app-01

- !grant
  role: !layer myapp
  member: !host app-01
POLICY
  
policy_result = api.load_policy 'bootstrap', policy

puts policy_result

policy = api.resource "cucumber:policy:bootstrap"

puts "Loaded policy:"
puts policy.attributes['policy_versions'].find{|pv| pv['version'] == policy_result.version}['policy_text']

group = api.resource "cucumber:group:security_admin"
puts "Security admin group is:"
puts group
puts "Memberships are:"
puts group.memberships
puts "Members are:"
puts group.members

host_factory = api.resource "cucumber:host_factory:myapp"
puts "Host factory is:"
puts host_factory

token = host_factory.create_token (Time.now + 10.minutes).iso8601
token = Array(token).first
puts "New token:"
puts token

puts "Create a new host"
host = Conjur::API.host_factory_create_host token.token, "dynamic-host-01"
puts host

puts "Revoke the token"
token.revoke
