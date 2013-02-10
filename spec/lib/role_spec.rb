require 'spec_helper'

require 'conjur/api'

shared_examples_for "properties" do
  subject { role }
  its(:id) { should == id }
end

describe Conjur::Role do
  context "#new" do
    let(:url) { "#{Conjur::Authz::API.host}/roles/#{id}" }
    let(:credentials) { mock(:credentials) }
    let(:role) { Conjur::Role.new(url, credentials) }
    context "with plain id" do
      let(:id) { "foo" }
      it_should_behave_like "properties"
    end
    context "with more complex id" do
      let(:id) { "@foo;bar" }
      it_should_behave_like "properties"
    end
  end
end