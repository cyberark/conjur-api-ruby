require 'spec_helper'

require 'conjur/api'

shared_examples_for "API endpoint" do
  subject { api }
  let(:service_name) { api.name.split('::')[-2].downcase }
  context "in development" do
    before(:each) do
      Conjur.stub(:env).and_return "development"
    end
    its "default_host" do
      should == "http://localhost:#{Conjur.service_base_port + port_offset}"
    end
  end
  context "'ci' account" do
    before {
      Conjur.stub(:account).and_return 'ci'
    }
    context "in stage" do
      before(:each) do
        Conjur.stub(:env).and_return "stage"
      end
      its "default_host" do
        should == "https://#{service_name}-ci-conjur.herokuapp.com"
      end
    end
    context "in ci" do
      before(:each) do
        Conjur.stub(:env).and_return "ci"
      end
      its "default_host" do
        should == "https://#{service_name}-ci-conjur.herokuapp.com"
      end
    end
  end
end

describe Conjur::API do
  context "parse_role_id" do
    subject { Conjur::API }
    specify {
      Conjur::Core::API.should_receive(:conjur_account).and_return 'ci'      
      subject.parse_role_id('foo:bar').should == [ 'ci', 'roles', 'foo', 'bar' ]
    }
    specify {
      subject.parse_role_id('biz:foo:bar').should == [ 'biz', 'roles', 'foo', 'bar' ]
    }
    specify {
      subject.parse_role_id('biz:foo:bar/12').should == [ 'biz', 'roles', 'foo', 'bar/12' ]
    }
    specify {
      subject.parse_role_id('biz:foo:bar:12').should == [ 'biz', 'roles', 'foo', 'bar:12' ]
    }
  end
  context "host construction" do
    context "of authn service" do
      let(:port_offset) { 0 }
      let(:api) { Conjur::Authn::API }
      it_should_behave_like "API endpoint"
    end
    context "of authz service" do
      let(:port_offset) { 100 }
      let(:api) { Conjur::Authz::API }
      subject { api }
      context "'ci' account" do
        before {
          Conjur.stub(:account).and_return 'ci'
        }
        context "in stage" do
          before(:each) do
            Conjur.stub(:env).and_return "stage"
          end
          its "default_host" do
            should == "https://authz-stage-conjur.herokuapp.com"
          end
        end
        context "in ci" do
          before(:each) do
            Conjur.stub(:env).and_return "ci"
          end
          its "default_host" do
            should == "https://authz-ci-conjur.herokuapp.com"
          end
        end
      end
      context "in production" do
        before(:each) do
          Conjur.stub(:env).and_return "production"
        end
        its "default_host" do
          should == "https://authz-v3-conjur.herokuapp.com"
        end
      end
      context "in named production version" do
        before(:each) do
          Conjur.stub(:env).and_return "production"
          Conjur.stub(:stack).and_return "waffle"
        end
        its "default_host" do
          should == "https://authz-waffle-conjur.herokuapp.com"
        end
      end
    end
    context "of core service" do
      let(:port_offset) { 200 }
      let(:api) { Conjur::Core::API }
      it_should_behave_like "API endpoint"
    end    
  end
  context "credential handling" do
    let(:login) { "bob" }
    let(:token) { { 'data' => login, 'timestamp' => (Time.now + elapsed ).to_s } }
    let(:elapsed) { 0 }
    before {
      Conjur::TokenCache.class_variable_set("@@tokens", Hash.new)
    }
    subject { api }
    context "from token" do
      let(:api) { Conjur::API.new_from_token(token) }
      context "expired" do
        before {
          Conjur::TokenCache.stub(:expired?).and_return true
        }
        it "should raise an error" do
          $stderr.should_receive(:puts).with("Token will soon expire and no api_key is available to renew it")
          
          api.credentials
        end
      end
      context "not expired" do
        its(:credentials) { should == { headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login } }
      end
    end
    context "from api key" do
      let(:api_key) { "theapikey" }
      let(:api) { Conjur::API.new_from_key(login, api_key) }
      it("should authenticate to get a token") do
        Conjur::API.should_receive(:authenticate).with(login, api_key).and_return token
        
        api.instance_variable_get("@token").should == nil
        api.credentials.should == { headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login }
      end
    end
  end
end
