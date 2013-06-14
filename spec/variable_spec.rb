require 'spec_helper'

describe Conjur::Variable do
  let(:url) { "http://example.com/variable" }
  subject { Conjur::Variable.new url }

  before { subject.attributes = {'versions' => 42} }
  its(:version_count) { should == 42}

  describe '#add_value' do
    it "posts the new value" do
      RestClient::Request.should_receive(:execute).with(
        method: :post,
        url: "#{url}/values",
        payload: { value: 'new-value' },
        headers: {}
      )
      subject.add_value 'new-value'
    end
  end

  describe '#value' do
    it "gets the value" do
      RestClient::Request.stub(:execute).with(
        method: :get,
        url: "#{url}/value",
        headers: {}
      ).and_return(double "response", body: "the-value")
      subject.value.should == "the-value"
    end

    it "parametrizes the request with a version" do
      RestClient::Request.stub(:execute).with(
        method: :get,
        url: "#{url}/value?version=42",
        headers: {}
      ).and_return(double "response", body: "the-value")
      subject.value(42).should == "the-value"
    end
  end
end
