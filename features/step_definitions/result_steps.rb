Then(/^the result should be "([^"]+)"$/) do |expected|
  expect(@result.to_s).to eq(expected.to_s)
end

Then(/^the providers list contains service id "([^"]+)"$/) do |service_id|
  expect(@result.map{ |x| x["service_id"]}).to include(service_id)
end
