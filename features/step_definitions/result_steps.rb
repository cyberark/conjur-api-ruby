Then(/^the result should be "([^"]+)"$/) do |expected|
  expect(@result.to_s).to eq(expected.to_s)
end

Then(/^the result should be the public key$/) do
  expect(@result).to eq(@public_key + "\n")
end

Then(/^the providers list contains service id "([^"]+)"$/) do |service_id|
  service_ids = []
  @result.each do |provider|
    service_ids.append(provider["service_id"])
  end
  expect(service_ids).to include(service_id)
end
