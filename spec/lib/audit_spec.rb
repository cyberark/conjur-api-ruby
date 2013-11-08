require 'spec_helper'

describe Conjur::API, api: :dummy do 
  describe "audit API methods" do
    
    let(:options){ {limit:20, offset: 51, some_unwanted_option: 'heloo!'} }
    let(:expected_options){ options.slice(:limit, :offset) }
    let(:response){ ['some event'] }
    let(:include_options){ false }
    let(:query){ include_options ? '?' + expected_options.to_query : '' }
    let(:expected_path){ nil }
    let(:expected_url){ "#{Conjur::Audit::API.host}/#{expected_path}#{query}" }
    
    def expect_request
      RestClient::Request.should_receive(:execute).with(
        user: credentials,
        password: nil,
        headers: {},
        url: expected_url,
        method: :get
      ).and_return response.to_json
    end
    
    
    describe "#audit_role" do
      let(:role_id){ 'acct:user:foobar' }
      let(:role){ double('role', roleid: role_id) }
      let(:expected_path){ "feeds/role/#{CGI.escape role_id}" }
      let(:args){ [role_id] }
      let(:full_args){ include_options ? args + [options] : args }
      shared_examples_for "gets roles feed" do
        it "GETs feeds/role/:role_id" do
          expect_request
          api.audit_role(*full_args).should == response
        end
      end
      
      context "when called with a role id" do
        let(:args){ [role_id] }
        it_behaves_like "gets roles feed"
      end
      
      context "when called with a role instance" do
        let(:audit_role_args){ [role] }
        it_behaves_like "gets roles feed"
      end
      
      context "when called with pagination options" do
        let(:include_options){ true }
        let(:args){ [ role_id ] }
        it_behaves_like  "gets roles feed"
      end
    end
    
    describe "#audit_current_role" do
      let(:expected_path){ "feeds/role" }
      let(:args){ include_options ? [options] : [] }
      shared_examples_for "gets current role feed" do
        it "GETS feeds/role" do
          expect_request
          api.audit_current_role(*args).should == response
        end
      end
      context "when called with no args" do 
        it_behaves_like "gets current role feed"
      end
      context "when called with pagination options" do
        let(:include_options){ true }
        it_behaves_like "gets current role feed"
      end
    end
    
    describe "#audit_resource" do
      let(:resource_id){ 'acct:food:bacon' }
      let(:resource){ double('resource', resourceid: resource_id) }
      let(:expected_path){ "feeds/resource/#{CGI.escape resource_id}" }
      let(:args){[resource_id]}
      let(:full_args){ include_options ? args + [options] : args }
      shared_examples_for "gets the resource feed" do
        it "GETS feeds/resource/:resource_id" do
          expect_request
          api.audit_resource(*full_args).should == response
        end
      end
      
      context "when called with resource id" do
        let(:args){ [resource_id] }
        it_behaves_like "gets the resource feed"
      end
      
      context "when called with resource instance" do
        let(:args){ [resource] }
        it_behaves_like "gets the resource feed"
      end
      
      context "when called with pagination options" do
        let(:include_options) { true }
        it_behaves_like "gets the resource feed"
      end
    end
  end
end