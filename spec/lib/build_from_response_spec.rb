require 'spec_helper'

describe Conjur::BuildFromResponse do
  describe "::build_from_response" do
    let(:location) { "http://example.com" }
    let(:attrs) {{ 'some' => 'foo', 'other' => 'bar' }}
    let(:response) do
      double "response", headers: { location: location }, body: attrs.to_json
    end
    subject { double "class" }
    let(:constructed) { double "object" }
    let(:credentials) { "whatever" }

    it "passes the location credentials and attributes" do
      subject.extend Conjur::BuildFromResponse
      subject.should_receive(:new).with(location, credentials).and_return constructed
      constructed.should_receive(:attributes=).with attrs
      subject.build_from_response response, credentials
    end
  end
end
