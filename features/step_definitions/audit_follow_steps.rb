
Given(/^a role and resource$/) do
  create_role
  create_resource
end

When(/^I follow the audit feed$/) do
  start_follower do |e|
    e['resource'] == resource.resourceid and e['role'] == role.roleid and e['action'].to_s == 'check'
  end
end

When(/^I perform a permission check$/) do
  check_permission
end

Then(/^the permission check appears in the audit feed$/) do
  await_follower
end
