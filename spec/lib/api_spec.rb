require 'spec_helper'

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
        expect { subject.parse_id({}, kind) }.to raise_error /Unexpected class/
      end
      
      it "fails on malformed ids (<2 tokens)" do
        expect { subject.parse_id("foo", kind) }.to raise_error /Expecting at least two /
        expect { subject.parse_id("", kind) }.to raise_error /Expecting at least two /
        expect { subject.parse_id(nil, kind) }.to raise_error /Unexpected class/
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

  shared_context "logged in", logged_in: true do
    let(:login) { "bob" }
    let(:token) { { 'data' => login, 'timestamp' => Time.now.to_s } }
    let(:remote_ip) { nil }
    let(:api_args) { [ token, remote_ip ].compact }
    subject(:api) { Conjur::API.new_from_token(*api_args) }
    let(:account) { 'some-account' }
    before { allow(Conjur::Core::API).to receive_messages conjur_account: account }
  end

  shared_context "logged in with an API key", logged_in: :api_key do
    include_context "logged in"
    let(:api_key) { "theapikey" }
    let(:api_args) { [ login, api_key, remote_ip ].compact }
    subject(:api) { Conjur::API.new_from_key(*api_args) }
  end

  shared_context "logged in with a token file", logged_in: :token_file do
    include_context "logged in"
    let(:token_file) { "/path/to/token_file" }
    let(:api_args) { [ token_file, remote_ip ].compact }
    subject(:api) { Conjur::API.new_from_token_file(*api_args) }
  end

  def time_travel delta
    allow(api.send :authenticator).to receive(:gettime).and_wrap_original do |m|
      m[] + delta
    end
  end

  describe '#token' do
    context 'with token file available', logged_in: :token_file do
      before {
        expect(File).to receive(:mtime).at_least(1).and_return(Time.now)
        expect(File).to receive(:read).at_least(1).and_return(JSON.generate(token))
      }
      it "reads the file to get a token" do
        expect(api.instance_variable_get("@token")).to eq(nil)
        expect(api.token).to eq(token)
        expect(api.credentials).to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login })
      end

      context "after expiration" do
        it 'it reads a new token' do
          expect(Time.parse(api.token['timestamp'])).to be_within(5.seconds).of(Time.now)
          
          time_travel 6.minutes
          new_token = token.merge "timestamp" => Time.now.to_s
          
          expect(api.token).to eq(new_token)
        end
      end
    end

    context 'with API key available', logged_in: :api_key do
      it "authenticates to get a token" do
        expect(Conjur::API).to receive(:authenticate).with(login, api_key).and_return token

        expect(api.instance_variable_get("@token")).to eq(nil)
        expect(api.token).to eq(token)
        expect(api.credentials).to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login })
      end

      context "after expiration" do

        shared_examples "it gets a new token" do
          it 'by refreshing' do
            allow(Conjur::API).to receive(:authenticate).with(login, api_key).and_return token
            expect(Time.parse(api.token['timestamp'])).to be_within(5.seconds).of(Time.now)
            
            time_travel 6.minutes
            new_token = token.merge "timestamp" => Time.now.to_s
            
            expect(Conjur::API).to receive(:authenticate).with(login, api_key).and_return new_token
            expect(api.token).to eq(new_token)
          end
        end

        it_should_behave_like "it gets a new token"
        
        context "with elevated privilege" do
          subject(:api) { Conjur::API.new_from_key(*api_args).with_privilege('reveal') }
          it_should_behave_like "it gets a new token"
        end

        context "with audit roles" do
          subject(:api) { Conjur::API.new_from_key(*api_args).with_audit_roles('account:host:host1') }
          it_should_behave_like "it gets a new token"
        end

        context "with audit resources" do
          subject(:api) { Conjur::API.new_from_key(*api_args).with_audit_resources('account:webservice:service1') }
          it_should_behave_like "it gets a new token"
        end

      end
    end

    context 'with no API key available', logged_in: true do
      it "returns the token used to create it" do
        expect(api.token).to eq token
      end

      it "doesn't try to refresh an old token" do
        expect(Conjur::API).not_to receive :authenticate
        api.token # vivify
        time_travel 6.minutes
        expect { api.token }.not_to raise_error
      end
    end
  end

  context "credential handling", logged_in: true do
    context "from token" do
      describe '#credentials' do
        subject { super().credentials }
        it { is_expected.to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"" }, username: login }) }
      end
      
      describe "privileged" do
        describe '#credentials' do
          subject { super().with_privilege('elevate').credentials }
          it { is_expected.to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"", :x_conjur_privilege=>"elevate" }, username: login }) }
        end
      end
      
      context "with remote_ip" do
        let(:remote_ip) { "66.0.0.1" }
        describe '#credentials' do
          subject { super().credentials }
          it { is_expected.to eq({ headers: { authorization: "Token token=\"#{Base64.strict_encode64(token.to_json)}\"", :x_forwarded_for=>"66.0.0.1" }, username: login }) }
        end
      end
    end

    context "from logged-in RestClient::Resource" do
      let (:authz_header) { %Q{Token token="#{token_encoded}"} }
      let (:priv_header) { nil }
      let (:forwarded_for_header) { nil }
      let (:audit_roles_header) { nil }
      let (:audit_resources_header) { nil }
      let (:username) { 'bob' }
      subject { resource.conjur_api }

      shared_examples "it can clone itself" do
        it "has the authz header" do
          expect(subject.credentials[:headers][:authorization]).to eq(authz_header)
        end
        it "has the conjur privilege header" do
          expect(subject.credentials[:headers][:x_conjur_privilege]).to eq(priv_header)
        end
        it "has the forwarded for header" do
          expect(subject.credentials[:headers][:x_forwarded_for]).to eq(forwarded_for_header)
        end
        it "has the audit_roles header" do
          expect(subject.credentials[:headers][:conjur_audit_roles]).to eq(audit_roles_header)
        end
        it "has the audit_resources header" do
          expect(subject.credentials[:headers][:conjur_audit_resources]).to eq(audit_resources_header)
        end
        it "has the username" do
          expect(subject.credentials[:username]).to eq(username)
        end
      end

      let(:token_encoded) { Base64.strict_encode64(token.to_json) }
      let(:base_headers) { { authorization: authz_header } }
      let(:headers) { base_headers }
      let(:resource) { RestClient::Resource.new("http://example.com", { headers: headers })}
      context 'basic functioning' do
        it_behaves_like 'it can clone itself'
      end
      
      context "privileged" do
        let(:priv_header) { 'elevate' }
        let(:headers) { base_headers.merge(x_conjur_privilege: priv_header) }
        it_behaves_like "it can clone itself"
      end
      
      context "forwarded for" do
        let(:forwarded_for_header) { "66.0.0.1" }
        let(:headers) { base_headers.merge(x_forwarded_for: forwarded_for_header) }
        it_behaves_like 'it can clone itself'
      end

      context "audit roles" do
        let(:audit_roles_header) { Conjur::API.encode_audit_ids(['account:kind:role1', 'account:kind:role2']) }
        let(:headers) { base_headers.merge(:conjur_audit_roles => audit_roles_header) }
        it_behaves_like 'it can clone itself'
      end

      context "audit resources" do
        let(:audit_resources_header) { Conjur::API.encode_audit_ids(['account:kind:resource1', 'account:kind:resource2']) }
        let(:headers) { base_headers.merge(:conjur_audit_resources => audit_resources_header) }
        it_behaves_like 'it can clone itself'
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

  describe 'url escapes' do
    let(:urls){[
        'foo/bar@baz',
        '/test/some group with spaces'
    ]}

    describe '#fully_escape' do
      let(:expected){[
        'foo%2Fbar%40baz',
        '%2Ftest%2Fsome%20group%20with%20spaces'
      ]}
      it 'escapes the urls correctly' do
        expect(urls.map{|u| Conjur::API.fully_escape u}).to eq(expected)
      end
    end
  end
end
