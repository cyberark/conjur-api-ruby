require 'spec_helper'

require 'conjur/api'

shared_examples_for "API endpoint" do
  subject { api }
  let(:service_name) { api.name.split('::')[-2].downcase }
  context "development" do
    before(:each) do
      Conjur.stub(:env).and_return "development"
    end
    its "default_host" do
      should == "http://localhost:#{Conjur.service_base_port + port_offset}"
    end
  end
  context "stage" do
    before(:each) do
      Conjur.stub(:env).and_return "stage"
    end
    its "default_host" do
      should == "https://conjur-#{service_name}-stage.herokuapp.com"
    end
  end
  context "ci" do
    before(:each) do
      Conjur.stub(:env).and_return "ci"
    end
    its "default_host" do
      should == "https://conjur-#{service_name}-ci.herokuapp.com"
    end
  end
  context "production" do
    before(:each) do
      Conjur.stub(:env).and_return "production"
    end
    its "default_host" do
      should == "https://conjur-#{service_name}-v2.herokuapp.com"
    end
  end
  context "named production version" do
    before(:each) do
      Conjur.stub(:env).and_return "production"
      Conjur.stub(:stack).and_return "waffle"
    end
    its "default_host" do
      should == "https://conjur-#{service_name}-waffle.herokuapp.com"
    end
  end
end

describe Conjur::API do
  context "authn service" do
    let(:port_offset) { 0 }
    let(:api) { Conjur::Authn::API }
    it_should_behave_like "API endpoint"
  end
  context "authz service" do
    let(:port_offset) { 100 }
    let(:api) { Conjur::Authz::API }
    it_should_behave_like "API endpoint"
  end
  context "das service" do
    let(:port_offset) { 200 }
    let(:api) { Conjur::DAS::API }
    it_should_behave_like "API endpoint"
  end
  context "core service" do
    let(:port_offset) { 300 }
    let(:api) { Conjur::Core::API }
    it_should_behave_like "API endpoint"
  end
end
