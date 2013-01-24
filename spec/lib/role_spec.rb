require 'spec_helper'

require 'conjur/api'

shared_examples_for "properties" do
  subject { role }
  its(:identifier) { should == identifier }
end

describe Conjur::Role do
  context "#new" do
    let(:url) { "#{Conjur::Authz::API.host}/roles/#{identifier}" }
    let(:credentials) { mock(:credentials) }
    let(:role) { Conjur::Role.new(url, credentials) }
    context "with plain identifier" do
      let(:identifier) { "foo" }
      it_should_behave_like "properties"
    end
    context "with more complex identifier" do
      let(:identifier) { "@foo;bar" }
      it_should_behave_like "properties"
    end
  end
end