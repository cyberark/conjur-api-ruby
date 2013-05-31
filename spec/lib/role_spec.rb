require 'spec_helper'

shared_examples_for "properties" do
  subject { role }
  its(:kind) { should == kind }
  its(:id) { should == id }
end

describe Conjur::Role do
  let(:account) { "the-account" }
  context "#new" do
    let(:kind) { "test" }
    let(:role) { Conjur::API.new_from_token({ 'data' => 'the-login' }).role([ account, kind, id ].join(":")) }
    context "with plain id" do
      let(:id) { "foo" }
      context "credentials" do
        subject { role }
        its(:options) { should == {:headers=>{:authorization=>"Token token=\"eyJkYXRhIjoidGhlLWxvZ2luIn0=\""}, :username=>'the-login'} }
      end
      it_should_behave_like "properties"
    end
    context "with more complex id" do
      let(:id) { "foo/bar" }
      it_should_behave_like "properties"
    end
  end
end