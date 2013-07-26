require 'spec_helper'

describe Conjur::Host, api: :dummy do
  subject { Conjur::Host.new 'http://example.com/hosts/my/hostname', nil }

  its(:resource) { should be }
  its(:login) { should == 'host/my/hostname' }

  let(:api_key) { 'theapikey' }
  before { subject.attributes = { 'api_key' => api_key } }
  its(:api_key) { should == api_key }

  it "fetches enrollment_url" do
    stub_request(:head, "http://example.com/hosts/my/hostname/enrollment_url").
         to_return(:status => 200, :headers => {location: 'foo'})
    subject.enrollment_url.should == 'foo'
  end
end
