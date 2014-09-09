require 'spec_helper'
require 'timecop'

shared_examples_for "API endpoint" do
  before { Conjur.configuration = Conjur::Configuration.new }
  subject { api }
  let(:service_name) { api.name.split('::')[-2].downcase }
  context "in development" do
    before(:each) do
      allow_any_instance_of(Conjur::Configuration).to receive(:env).and_return "development"
    end

    describe '#host' do
      subject { super().host }
      it do
      is_expected.to eq("http://localhost:#{Conjur.configuration.service_base_port + port_offset}")
    end
    end
  end
  context "'ci' account" do
    before {
      allow_any_instance_of(Conjur::Configuration).to receive(:account).and_return 'ci'
    }
    context "in stage" do
      before(:each) do
        allow_any_instance_of(Conjur::Configuration).to receive(:env).and_return "stage"
      end

      describe '#host' do
        subject { super().host }
        it do
        is_expected.to eq("https://#{service_name}-ci-conjur.herokuapp.com")
      end
      end
    end
    context "in ci" do
      before(:each) do
        allow_any_instance_of(Conjur::Configuration).to receive(:env).and_return "ci"
      end

      describe '#host' do
        subject { super().host }
        it do
        is_expected.to eq("https://#{service_name}-ci-conjur.herokuapp.com")
      end
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
          before(:each) { allow(Conjur::Core::API).to receive(:conjur_account).and_return current_account }

          it "account: current account" do
            expect(subject[0]).to eq(current_account)
          end

          it "kind: passed kind" do
            expect(subject[1]).to eq(kind)
          end

          it "subkind: token #1 (escaped)" do
            expect(subject[2]).to eq(escaped("token#1"))
          end

          it "id: token #2 (escaped)" do
            expect(subject[3]).to eq(escaped("token#2"))
          end
        end

        context "for long ids (3+ tokens)" do
          let(:id) { "token#1:token#2:token#3:token#4" }
          it "account: token #1 (escaped)" do
            expect(subject[0]).to eq(escaped("token#1"))
          end

          it "kind: passed kind" do
            expect(subject[1]).to  eq(kind)
          end
          it "subkind: token #2 (escaped)" do
            expect(subject[2]).to eq(escaped("token#2"))
          end
          it "id: tail of id starting from token#3" do
            expect(subject[3]).to eq(escaped("token#3:token#4"))
          end
        end

      end
    end 
    describe "wrapper functions" do
      let(:result) { [:account,:kind,:id] }
      let(:id)     { :input_id }

      it "#parse_role_id(id): calls parse_id(id, 'roles') and returns result" do
        expect(Conjur::API).to receive(:parse_id).with(id, 'roles').and_return(result)
        expect(Conjur::API.parse_role_id(id)).to eq(result)
      end
      it "#parse_resource_id(id): calls parse_id(id, 'resources') and returns result" do
        expect(Conjur::API).to receive(:parse_id).with(id, 'resources').and_return(result)
        expect(Conjur::API.parse_resource_id(id)).to eq(result)
      end
    end
  end

  context "host construction" do
    before { Conjur.configuration = Conjur::Configuration.new }
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
          allow_any_instance_of(Conjur::Configuration).to receive(:account).and_return 'ci'
        }
        context "in stage" do
          before(:each) do
            allow_any_instance_of(Conjur::Configuration).to receive(:env).and_return "stage"
          end

          describe '#host' do
            subject { super().host }
            it do
            is_expected.to eq("https://authz-stage-conjur.herokuapp.com")
          end
          end
        end
        context "in ci" do
          before(:each) do
            # Looks at "ENV['CONJUR_STACK']" first, stub this out
            allow(ENV).to receive(:[]).with('CONJUR_STACK').and_return nil
            allow_any_instance_of(Conjur::Configuration).to receive(:env).and_return "ci"
          end

          describe '#host' do
            subject { super().host }
            it do
            is_expected.to eq("https://authz-ci-conjur.herokuapp.com")
          end
          end
        end
        context "when ENV['CONJUR_STACK'] is set to 'v12'" do
          before do
            allow_any_instance_of(Conjur::Configuration).to receive(:stack).and_return "v12"
            allow_any_instance_of(Conjur::Configuration).to receive(:env).and_return "ci"
          end

          describe '#host' do
            subject { super().host }
            it { is_expected.to eq("https://authz-v12-conjur.herokuapp.com")}
          end
        end
      end
      context "in production" do
        before(:each) do
          allow_any_instance_of(Conjur::Configuration).to receive(:env).and_return "production"
        end

        describe '#host' do
          subject { super().host }
          it do
          is_expected.to eq("https://authz-v4-conjur.herokuapp.com")
        end
        end
      end
      context "in appliance" do
        before(:each) do
          allow_any_instance_of(Conjur::Configuration).to receive(:env).and_return "appliance"
        end

        describe '#host' do
          subject { super().host }
          it do
          is_expected.to eq("http://localhost:5100")
        end
        end
      end
      context "in named production version" do
        before(:each) do
          allow_any_instance_of(Conjur::Configuration).to receive(:env).and_return "production"
          allow_any_instance_of(Conjur::Configuration).to receive(:stack).and_return "waffle"
        end

        describe '#host' do
          subject { super().host }
          it do
          is_expected.to eq("https://authz-waffle-conjur.herokuapp.com")
        end
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
    let(:token) { { 'data' => login, 'timestamp' => Time.now.to_s } }
    subject { api }
    let(:api) { Conjur::API.new_from_token(token) }
    let(:account) { 'some-account' }
    before { allow(Conjur::Core::API).to receive_messages conjur_account: account }
  end

  context "credential handling", logged_in: true do
    context "from token" do
      describe '#token' do
        subject { super().token }
        it { is_expected.to eq(token) }
      end

      describe '#credentials' do
        subject { super().credentials }
        it { is_expected.to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login }) }
      end
    end

    context "from api key", logged_in: true do
      let(:api_key) { "theapikey" }
      let(:api) { Conjur::API.new_from_key(login, api_key) }
      subject { api }

      it("should authenticate to get a token") do
        expect(Conjur::API).to receive(:authenticate).with(login, api_key).and_return token
        
        expect(api.instance_variable_get("@token")).to eq(nil)
        expect(api.token).to eq(token)
        expect(api.credentials).to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login })
      end

      context "with an expired token" do
        it "fetches a new one" do
          allow(Conjur::API).to receive(:authenticate).with(login, api_key).and_return token
          expect(Time.parse(api.token['timestamp'])).to be_within(5.seconds).of(Time.now)

          Timecop.travel Time.now + 6.minutes
          new_token = token.merge "timestamp" => Time.now.to_s

          expect(Conjur::API).to receive(:authenticate).with(login, api_key).and_return new_token
          expect(api.token).to eq(new_token)
        end
      end
    end

    context "from logged-in RestClient::Resource" do
      let(:token_encoded) { Base64.strict_encode64(token.to_json) }
      let(:resource) { RestClient::Resource.new("http://example.com", { headers: { authorization: "Token token=\"#{token_encoded}\"" } })}
      it "can construct a new API instance" do
        api = resource.conjur_api
        expect(api.credentials[:headers][:authorization]).to eq("Token token=\"#{token_encoded}\"")
        expect(api.credentials[:username]).to eq("bob")
      end
    end
  end

  describe "#role_from_username", logged_in: true do
    it "returns a user role when username is plain" do
      expect(api.role_from_username("plain-username").roleid).to eq("#{account}:user:plain-username")
    end

    it "returns an appropriate role kind when username is qualified" do
      expect(api.role_from_username("host/foo/bar").roleid).to eq("#{account}:host:foo/bar")
    end
  end

  describe "#current_role", logged_in: true do
    context "when logged in as user" do
      let(:login) { 'joerandom' }
      it "returns a user role" do
        expect(api.current_role.roleid).to eq("#{account}:user:joerandom")
      end
    end

    context "when logged in as host" do
      let(:host) { "somehost" }
      let(:login) { "host/#{host}" }
      it "returns a host role" do
        expect(api.current_role.roleid).to eq("#{account}:host:somehost")
      end
    end
  end
end
