require 'spec_helper'

describe Conjur::Variable do
  let(:url) { "http://example.com/variable" }
  subject(:variable) { Conjur::Variable.new url }

  before { subject.attributes = {'version_count' => 42} }

  describe '#version_count' do
    it "is read from the attributes" do
      expect(variable.version_count).to eq(42)
    end
  end

  describe '#add_value' do
    it "posts the new value" do
      expect(RestClient::Request).to receive(:execute).with(
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
      allow(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "#{url}/value",
        headers: {}
      ).and_return(double "response", body: "the-value")
      expect(subject.value).to eq("the-value")
    end

    it "parametrizes the request with a version" do
      allow(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "#{url}/value?version=42",
        headers: {}
      ).and_return(double "response", body: "the-value")
      expect(subject.value(42)).to eq("the-value")
    end
  end
end
