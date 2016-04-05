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
  #eval(code.gsub('$ns', namespace))
  step %Q{I evaluate the expression "#{code}"}
end
