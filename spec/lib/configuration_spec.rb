require 'spec_helper'

describe Conjur::Configuration do
  before {
    Conjur.configuration = Conjur::Configuration.new
  }
  subject { Conjur.configuration }
  context "CONJUR_ENV unspecified" do
    before {
      ENV.delete('CONJUR_ENV')
    }
    context "default env" do
      its(:env) { should == "production" }
    end
    context "default stack" do
      its(:stack) { should == "v4" }
    end
    describe 'authn_url' do
      before {
        Conjur::Configuration.any_instance.stub(:account).and_return "the-account"
      }
      context "with appliance_url" do
        before {
          Conjur::Configuration.any_instance.stub(:appliance_url).and_return "http://example.com"
        }
        its(:authn_url) { should == "http://example.com/authn" }
      end
      context "without appliance_url" do
        its(:authn_url) { should == "https://authn-the-account-conjur.herokuapp.com" }
      end
    end
    describe 'authz_url' do
      before {
        Conjur::Configuration.any_instance.stub(:account).and_return "the-account"
      }
      context "with appliance_url" do
        before {
          Conjur::Configuration.any_instance.stub(:appliance_url).and_return "http://example.com"
        }
        its(:authz_url) { should == "http://example.com/authz" }
      end
      context "without appliance_url" do
        its(:authz_url) { should == "https://authz-v4-conjur.herokuapp.com" }
        context "with specific stack" do
          before { Conjur::Configuration.any_instance.stub(:stack).and_return "the-stack" }
          its(:authz_url) { should == "https://authz-the-stack-conjur.herokuapp.com" }
        end
      end
    end
  end
  context "CONJUR_ENV = 'test'" do
    its(:env) { should == "test" }
    before {
      Conjur::Configuration.any_instance.stub(:account).and_return "the-account"
    }
    describe 'authn_url' do
      context "with appliance_url hostname" do
        before {
          Conjur::Configuration.any_instance.stub(:appliance_url).and_return "http://example.com"
        }
        its(:authn_url) { should == "http://example.com/authn" }
      end
      context "with appliance_url hostname and non-trailing-slash path" do
        before {
          Conjur::Configuration.any_instance.stub(:appliance_url).and_return "http://example.com/api"
        }
        its(:authn_url) { should == "http://example.com/api/authn" }
      end
      context "without appliance_url" do
        its(:authn_url) { should == "http://localhost:5000" }
      end
    end
    describe 'authz_url' do
      context "with appliance_url" do
        before {
          Conjur::Configuration.any_instance.stub(:appliance_url).and_return "http://example.com/api/"
        }
        its(:authz_url) { should == "http://example.com/api/authz" }
      end
      context "without appliance_url" do
        its(:authz_url) { should == "http://localhost:5100" }
      end
    end
    describe 'core_url' do
      context "with appliance_url" do
        before {
          Conjur::Configuration.any_instance.stub(:appliance_url).and_return "http://example.com/api"
        }
        its(:core_url) { should == "http://example.com/api" }
      end
      context "without appliance_url" do
        its(:core_url) { should == "http://localhost:5200" }
      end
    end
  end
end
