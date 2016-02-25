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

Then(/^expression "([^"]*)" includes "([^"]*)"$/) do |code, test|
  expect(eval(code)).to include(eval(test))
end
