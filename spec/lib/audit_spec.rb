require 'spec_helper'
require 'active_support/core_ext/object/to_query'
describe Conjur::API, api: :dummy do 
  describe "audit API methods" do
    
    let(:options){ {since:Time.at(0).to_s, till: Time.now.to_s, some_unwanted_option: 'heloo!'} }
    let(:expected_options){ options.slice(:since, :till) }
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
    
    
    describe "#audit" do
      let(:expected_path){ '' }
      let(:args){ [] }
      let(:full_args){ include_options ? args + [options] : args }
      
      shared_examples_for "gets all visible events" do
        it "GETs /" do
          expect_request
          api.audit(*full_args).should == response
        end
      end
      
      context "when called without options" do
        let(:include_options){ false }
        it_behaves_like "gets all visible events"
      end
      
      context "when called with time options" do
        let(:include_options){ true }
        it_behaves_like "gets all visible events"
      end
    end
    
    describe "#audit_role" do
      let(:role_id){ 'acct:user:foobar' }
      let(:role){ double('role', roleid: role_id) }
      let(:expected_path){ "roles/#{CGI.escape role_id}" }
      let(:args){ [role_id] }
      let(:full_args){ include_options ? args + [options] : args }
      shared_examples_for "gets roles feed" do
        it "GETs roles/:role_id" do
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
      
      context "when called with time options" do
        let(:include_options){ true }
        let(:args){ [ role_id ] }
        it_behaves_like  "gets roles feed"
      end
    end
    
    
    describe "#audit_resource" do
      let(:resource_id){ 'acct:food:bacon' }
      let(:resource){ double('resource', resourceid: resource_id) }
      let(:expected_path){ "resources/#{CGI.escape resource_id}" }
      let(:args){[resource_id]}
      let(:full_args){ include_options ? args + [options] : args }
      shared_examples_for "gets the resource feed" do
        it "GETS resources/:resource_id" do
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
      
      context "when called with time options" do
        let(:include_options) { true }
        it_behaves_like "gets the resource feed"
      end
    end
  end
end