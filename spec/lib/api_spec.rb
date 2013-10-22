require 'spec_helper'

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
  describe "provides functions for id parsing" do
    describe "#parse_id(id, kind)" do
      subject { Conjur::API } 
      let (:kind) { "sample-kind" }

      it "fails  on non-string ids" do
        expect { subject.parse_id({}, kind) }.to raise_error
      end
      
      it "fails on malformed ids (<2 tokens)" do
        expect { subject.parse_id("foo", kind) }.to raise_error
        expect { subject.parse_id("", kind) }.to raise_error
        expect { subject.parse_id(nil, kind) }.to raise_error
      end
     
      describe "returns array of [account, kind, subkind, id]" do
        subject { Conjur::API.parse_id(id, kind) }
        def escaped smth ; Conjur::API.path_escape(smth) ; end
        
        context "for short id (2 tokens)" do
          let(:id) { "token#1:token#2" }
          let(:current_account) { "current_account" }
          before(:each) { Conjur::Core::API.stub(:conjur_account).and_return current_account }

          it "account: current account" do
            subject[0].should == current_account
          end

          it "kind: passed kind" do
            subject[1].should == kind
          end

          it "subkind: token #1 (escaped)" do
            subject[2].should == escaped("token#1")
          end

          it "id: token #2 (escaped)" do
            subject[3].should == escaped("token#2")
          end
        end

        context "for long ids (3+ tokens)" do
          let(:id) { "token#1:token#2:token#3:token#4" }
          it "account: token #1 (escaped)" do
            subject[0].should == escaped("token#1")
          end

          it "kind: passed kind" do
            subject[1].should  == kind
          end
          it "subkind: token #2 (escaped)" do
            subject[2].should == escaped("token#2")
          end
          it "id: tail of id starting from token#3" do
            subject[3].should == escaped("token#3:token#4")
          end
        end

      end
    end 
    describe "wrapper functions" do
      let(:result) { [:account,:kind,:id] }
      let(:id)     { :input_id }

      it "#parse_role_id(id): calls parse_id(id, 'roles') and returns result" do
        Conjur::API.should_receive(:parse_id).with(id, 'roles').and_return(result)
        Conjur::API.parse_role_id(id).should == result
      end
      it "#parse_resource_id(id): calls parse_id(id, 'resources') and returns result" do
        Conjur::API.should_receive(:parse_id).with(id, 'resources').and_return(result)
        Conjur::API.parse_resource_id(id).should == result
      end
    end
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
            # Looks at "ENV['CONJUR_STACK']" first, stub this out
            ENV.stub(:[]).with('CONJUR_STACK').and_return nil
            Conjur.stub(:env).and_return "stage"
          end
          its "default_host" do
            should == "https://authz-stage-conjur.herokuapp.com"
          end
        end
        context "in ci" do
          before(:each) do
            # Looks at "ENV['CONJUR_STACK']" first, stub this out
            ENV.stub(:[]).with('CONJUR_STACK').and_return nil
            Conjur.stub(:env).and_return "ci"
          end
          its "default_host" do
            should == "https://authz-ci-conjur.herokuapp.com"
          end
        end
        context "when ENV['CONJUR_STACK'] is set to 'v12'" do
          before do
            ENV.stub(:[]).and_call_original
            ENV.stub(:[]).with('CONJUR_STACK').and_return 'v12'
            # If the "real" env is used ('test') then the URL is always localhost:<someport>
            Conjur.stub(:env).and_return "ci"
          end
          its(:default_host){ should == "https://authz-v12-conjur.herokuapp.com"}
        end
      end
      context "in production" do
        before(:each) do
          Conjur.stub(:env).and_return "production"
        end
        its "default_host" do
          should == "https://authz-v4-conjur.herokuapp.com"
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

  shared_context logged_in: true do
    let(:login) { "bob" }
    let(:token) { { 'data' => login, 'timestamp' => (Time.now + elapsed ).to_s } }
    let(:elapsed) { 0 }
    subject { api }
    let(:api) { Conjur::API.new_from_token(token) }
    let(:account) { 'some-account' }
    before { Conjur::Core::API.stub conjur_account: account }
  end

  context "credential handling", logged_in: true do
    context "from token" do
      its(:token) { should == token }
      its(:credentials) { should == { headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login } }
    end
    context "from api key", logged_in: true do
      let(:api_key) { "theapikey" }
      let(:api) { Conjur::API.new_from_key(login, api_key) }
      subject { api }
      it("should authenticate to get a token") do
        Conjur::API.should_receive(:authenticate).with(login, api_key).and_return token
        
        api.instance_variable_get("@token").should == nil
        api.token.should == token
        api.credentials.should == { headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login }
      end
    end
  end

  describe "#role_from_username", logged_in: true do
    it "returns a user role when username is plain" do
      api.role_from_username("plain-username").roleid.should == "#{account}:user:plain-username"
    end

    it "returns an appropriate role kind when username is qualified" do
      api.role_from_username("host/foo/bar").roleid.should == "#{account}:host:foo/bar"
    end
  end

  describe "#current_role", logged_in: true do
    context "when logged in as user" do
      let(:login) { 'joerandom' }
      it "returns a user role" do
        api.current_role.roleid.should == "#{account}:user:joerandom"
      end
    end

    context "when logged in as host" do
      let(:host) { "somehost" }
      let(:login) { "host/#{host}" }
      it "returns a host role" do
        api.current_role.roleid.should == "#{account}:host:somehost"
      end
    end
  end
end
