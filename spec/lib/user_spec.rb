require 'spec_helper'

require 'conjur/api'

describe Conjur::User do
  context "#new" do
    let(:login) { 'the-login' }
    let(:api_key) { 'the-api-key' }
    let(:credentials) { { user: login, password: api_key } }
    let(:user) { Conjur::User.new(login, credentials)}
    describe "attributes" do
      subject { user }
      its(:id) { should == login }
      its(:login) { should == login }
      its(:resource_id) { should == login }
      its(:resource_kind) { should == "user" }
      its(:options) { should == credentials }
      specify {
        lambda { user.roleid }.should raise_error
      }
    end
    it "connects to a Resource" do
      require 'conjur/resource'
      Conjur::Core::API.should_receive(:conjur_account).and_return 'ci'
      Conjur::Resource.should_receive(:new).with(Conjur::Authz::API.host, credentials).and_return resource = double(:resource)
      resource.should_receive(:[]).with("ci/resources/user/the-login")
      
      user.resource
    end
    it "connects to a Role" do
      require 'conjur/role'
      Conjur::Core::API.should_receive(:conjur_account).and_return 'ci'
      Conjur::Role.should_receive(:new).with(Conjur::Authz::API.host, credentials).and_return role = double(:role)
      role.should_receive(:[]).with("ci/roles/user/the-login")
      
      user.role
    end
  end
end
