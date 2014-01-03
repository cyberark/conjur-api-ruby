require 'spec_helper'

describe Conjur::Host, api: :dummy do
  subject { Conjur::Host.new 'http://example.com/hosts/my%2Fhostname', nil }

  its(:resource) { should be }
  its(:login) { should == 'host/my/hostname' }

  it "fetches enrollment_url" do
    stub_request(:head, "http://example.com/hosts/my%2Fhostname/enrollment_url").
         to_return(:status => 200, :headers => {location: 'foo'})
    subject.enrollment_url.should == 'foo'
  end
end
