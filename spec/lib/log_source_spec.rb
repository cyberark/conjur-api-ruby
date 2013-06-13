require 'spec_helper'

describe Conjur::LogSource, logging: :temp, api: :dummy do
  describe "#log" do
    it "adds a username to the log" do
      api.log do |log|
        log << 'foo'
      end

      log.should == "[#{username}] foo\n"
    end
  end
end
