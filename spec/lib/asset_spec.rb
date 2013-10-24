require 'spec_helper'

describe Conjur::ActsAsAsset do
  let(:asset) { Object.new }
  before {
    class << asset
      include Conjur::ActsAsAsset
      
      def options
        OPTIONS
      end
    end
  }
  let(:invoke) {
    send action
  }
  let(:add_member) {
    asset.add_member ROLE, MEMBER, OPTIONS
  }
  let(:remove_member) {
    asset.remove_member ROLE, MEMBER
  }

  shared_context "asset with role" do
    before(:each) {
      asset.stub(:core_conjur_account).and_return(ACCOUNT)
      asset.stub(:resource_kind).and_return(KIND)
      asset.stub(:resource_id).and_return(ID)
      Conjur::Role.stub(:new).and_return(role_base)
    }
    let(:role_base) {
      double(:"[]" => role_instance)
    }
    let(:role_instance) { 
      double(grant_to: true, revoke_from: true)
    }
  end
  
  shared_examples_for "it obtains role via asset" do
    it "account=asset.core_conjur_account" do
      asset.should_receive(:core_conjur_account)
      invoke
    end
    it "kind=asset.resource_kind" do
      asset.should_receive(:resource_kind)
      invoke
    end
    it "id=asset.resource_id" do
      asset.should_receive(:resource_id)
      invoke
    end
    
    it "obtains role as #{ACCOUNT}:@:#{KIND}/#{ID}/#{ROLE}" do
      Conjur::Role.should_receive(:new).with("http://localhost:5100", {}).and_return role_base
      role_base.should_receive(:[]).with("#{CGI.escape ACCOUNT}/roles/@/#{KIND}/#{ID}/#{CGI.escape ROLE}").and_return role_instance
      
      invoke
    end   
  end
  
  describe "#add_member" do
    let(:action) { :add_member }
    include_context "asset with role"
    it_behaves_like "it obtains role via asset"
    it 'calls role.grant_to(member,...)' do
      role_instance.should_receive(:grant_to).with(MEMBER, anything)
      invoke
    end
  end
  
  describe "#remove_member" do
    let(:action) { :remove_member }
    include_context "asset with role"
    it_behaves_like "it obtains role via asset"
    it 'calls role.revoke_from(member)' do
      role_instance.should_receive(:revoke_from).with(MEMBER)
      invoke
    end
  end
end