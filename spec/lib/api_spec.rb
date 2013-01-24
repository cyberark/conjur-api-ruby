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
  context "in stage" do
    before(:each) do
      Conjur.stub(:env).and_return "stage"
    end
    its "default_host" do
      should == "https://#{service_name}-stage-conjur.herokuapp.com"
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
  context "in production" do
    before(:each) do
      Conjur.stub(:env).and_return "production"
    end
    its "default_host" do
      should == "https://#{service_name}-v2-conjur.herokuapp.com"
    end
  end
  context "in named production version" do
    before(:each) do
      Conjur.stub(:env).and_return "production"
      Conjur.stub(:stack).and_return "waffle"
    end
    its "default_host" do
      should == "https://#{service_name}-waffle-conjur.herokuapp.com"
    end
  end
end

describe Conjur::API do
  context "host construction" do
    context "of authn service" do
      let(:port_offset) { 0 }
      let(:api) { Conjur::Authn::API }
      it_should_behave_like "API endpoint"
    end
    context "of authz service" do
      let(:port_offset) { 100 }
      let(:api) { Conjur::Authz::API }
      it_should_behave_like "API endpoint"
    end
    context "of das service" do
      let(:port_offset) { 200 }
      let(:api) { Conjur::DAS::API }
      it_should_behave_like "API endpoint"
    end
    context "of core service" do
      let(:port_offset) { 300 }
      let(:api) { Conjur::Core::API }
      it_should_behave_like "API endpoint"
    end    
  end
  context "credential handling" do
    let(:login) { "bob" }
    subject { api }
    context "from token" do
      let(:token) { { data: login } }
      let(:api) { Conjur::API.new_from_token(token) }
      its(:credentials) { should == { headers: { authorization: "Conjur #{Base64.encode64(token.to_json)}" } } }
    end
    context "from api key" do
      let(:api_key) { "theapikey" }
      let(:api) { Conjur::API.new_from_key(login, api_key) }
      its(:credentials) { should == { user: login, password: api_key } }
    end
  end
end
