require 'spec_helper'

describe Conjur::Deputy, api: :dummy do
  subject { Conjur::Deputy.new 'http://example.com/deputies/my%2Fhostname', nil }

  its(:resource) { should be }
  its(:login) { should == 'deputy/my/hostname' }

  let(:api_key) { 'theapikey' }
  before { subject.attributes = { 'api_key' => api_key } }
  its(:api_key) { should == api_key }
end
