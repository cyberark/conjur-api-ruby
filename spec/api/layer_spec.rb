require 'spec_helper'
require 'webmock/rspec'

describe Conjur::Layer do
  subject { Conjur::Layer.new 'http://example.com/layers/my%2Flayername', nil }
  
  describe "#add_host" do
    it "casts Host to roleid" do
      host = double(:host)
      expect(host).to receive(:roleid).and_return "the-hostid"
      stub_request(:post, "http://example.com/layers/my%2Flayername/hosts").with(hostid: "the-hostid")

      subject.add_host host
    end
  end
end