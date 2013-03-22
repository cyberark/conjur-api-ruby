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
      its(:roleid) { should == ["user", login].join(':') }
      its(:resource_id) { should == login }
      its(:resource_kind) { should == "user" }
      its(:options) { should == credentials }
    end
    it "connects to a Resource" do
      require 'conjur/resource'
      Conjur::Resource.should_receive(:new).with("#{Conjur::Authz::API.host}/#{user.resource_kind}/#{user.resource_id}", credentials)
      
      user.resource
    end
    it "connects to a Role" do
      require 'conjur/role'
      Conjur::Role.should_receive(:new).with("#{Conjur::Authz::API.host}/roles/#{user.roleid}", credentials)
      
      user.role
    end
  end
end
