require 'spec_helper'

require 'conjur/api'

shared_examples_for "properties" do
  subject { role }
  its(:id) { should == [ kind, id ].join('/') }
end

describe Conjur::Role do
  let(:account) { "the-account" }
  context "#new" do
    let(:kind) { "test" }
    let(:role) { Conjur::API.new_from_key('the-user', 'the-key').role([ account, kind, id ].join(":")) }
    let(:token) { 'the-token' }
    before {
      Conjur::TokenCache.stub(:fetch).and_return token
    }
    context "with plain id" do
      let(:id) { "foo" }
      it_should_behave_like "properties"
    end
    context "with more complex id" do
      let(:id) { "@:foo/bar" }
      it_should_behave_like "properties"
    end
  end
end