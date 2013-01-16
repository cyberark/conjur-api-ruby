require 'spec_helper'

require 'conjur/api'

describe Conjur::API do
  context "data_access_service_url" do
    let(:account) { "the-account" }
    let(:path) { "upload" }
    subject { Conjur::API.data_access_service_url(account, path, params) }
    context "to test environment" do
      before(:each) do
        Conjur.stub(:env).and_return "development"
      end
      context "with empty params" do
        let(:params) { {} }
        it { should == "http://localhost:5200/data/the-account/inscitiv/upload" }
      end
      context "with params" do
        let(:params) { { "foo" => "b/r" } }
        it { should == "http://localhost:5200/data/the-account/inscitiv/upload?foo=b%2Fr" }
      end
    end
    context "to production environment" do
      before(:each) do
        Conjur.stub(:env).and_return "production"
      end
      context "with empty params" do
        let(:params) { {} }
        it { should == "https://das-v2-conjur.herokuapp.com/data/the-account/inscitiv/upload" }
      end
    end
  end
end
