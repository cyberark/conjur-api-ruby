Given(/^a new user$/) do
  @user_id = "user-#{random_hex}"
  response = $conjur.load_policy 'bootstrap', <<-POLICY
  - !user
    id: #{@user_id}
    uidnumber: 1000
  POLICY
  @user = $conjur.resource("cucumber:user:#{@user_id}")
  @user_api_key = response.created_roles["cucumber:user:#{@user_id}"]['api_key']
  expect(@user_api_key).to be
end

Given(/^a new group$/) do
  @group_id = "group-#{random_hex}"
  response = $conjur.load_policy 'bootstrap', <<-POLICY
  - !group
    id: #{@group_id}
    gidnumber: 1000
  POLICY
  @group = $conjur.resource("cucumber:group:#{@group_id}")
end

Given(/^a new host$/) do
  @host_id = "app-#{random_hex}"
  response = $conjur.load_policy 'bootstrap', <<-POLICY
  - !host #{@host_id}
  POLICY
  @host_api_key = response.created_roles["cucumber:host:#{@host_id}"]['api_key']
  expect(@host_api_key).to be
  @host = $conjur.resource("cucumber:host:#{@host_id}")
  @host.attributes['api_key'] = @host_api_key
end
