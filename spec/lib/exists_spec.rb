require 'spec_helper'

describe Conjur::Exists do
  subject { Object.new.tap {|o| o.send :extend, Conjur::Exists } }

  context "when head returns 200" do
    before { subject.stub head: "" }
    its(:exists?) { should be_true }
  end

  context "when forbidden" do
    before { subject.stub(:head) { raise RestClient::Forbidden }}
    it "propagates the error" do
      lambda { subject.exists? }.should raise_error(RestClient::Forbidden)
    end
  end

  context "when not found" do
    before { subject.stub(:head) { raise RestClient::ResourceNotFound }}
    its(:exists?) { should be_false }
  end
end
