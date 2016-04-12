Then(/^I bootstrap$/) do
  class Listener
    attr_accessor :messages
    
    def initialize
      @messages = []
    end
    
    def echo msg
      @messages.push msg
    end
  end
  @listener = Listener.new
  
  $conjur.bootstrap @listener
end

Then(/^expressions "([^"]*)" and "([^"]*)" are equal$/) do |code, test|
  expect(eval(code)).to eq(eval(test))
end

Then(/^expression "(.*?)" is equal to$/) do |code, test| 
  step %Q{expressions "#{code}" and "#{test}" are equal}
end
    
Then(/^expression "([^"]*)" includes "([^"]*)"$/) do |code, test|
  expect(eval(code)).to include(eval(test))
end

Then(/^I evaluate the expression "([^"]*)"$/) do |code|
  eval(code)
end

Then(/^I evaluate the expression$/) do |code|
  step %Q{I evaluate the expression "#{code}"}
end

Then(/^I create the variable "(.*?)"$/) do |var|
  api.create_variable('text/plain', 'secret', :id => var)
end

Then(/^I create an api with the additional audit (role|resource)[s]* "(.*?)"$/) do |type, things|
  @api = api.send("with_audit_#{type}s", things.split(','))
end

Then(/^I check to see if I'm permitted to "(.*?)" variable "(.*?)"$/) do |priv, var|
  api.variable(var).resource.permitted?(priv)
end

Then(/^an audit event for variable "(.*?)" with action "(.*?)" and (role|resource)[s]* "(.*?)" is generated$/) do |var, action, type, things|
  resource_ids = things.split(',').collect {|id| api.resource(id).resourceid }
  event_found = api.audit_resource(api.resource("variable:#{var}")).any? do |e|
    e['action'] == action &&
      Set.new(e["#{type}s"]).superset?(Set.new(resource_ids))
  end
  expect(event_found).to be true
end
