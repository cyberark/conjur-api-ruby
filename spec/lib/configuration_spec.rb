require 'spec_helper'

describe Conjur::Configuration do
  before {
    Conjur.configuration = Conjur::Configuration.new
  }
  let(:configuration) { Conjur.configuration }
  subject { configuration }
  context "thread-local behavior" do
    it "can swap the Configuration in a new thread" do
      original = Conjur.configuration
      c = Conjur::Configuration.new
      Thread.new do
        Thread.current[:conjur_configuration] = :foo
        Conjur.with_configuration c do
          Conjur.configuration.should == c
        end
        Thread.current[:conjur_configuration].should == :foo
      end.join
      Conjur.configuration.should == original
    end
  end
  context "with various options" do
    before {
      configuration.account = "the-account"
      configuration.appliance_url = "https://conjur/api"
    }

    context "and core_url fetched" do
      before { 
        configuration.core_url 
      }

      it "can still be changed by changing the appliance_url" do
        configuration.appliance_url = "https://other/api"
        expect(configuration.core_url).to eq "https://other/api"
      end

      context "and duplicated" do 
        subject { configuration.clone override_options }
        let(:override_options) { Hash.new }
        its(:account) { should == configuration.account }
        its(:appliance_url) { should == configuration.appliance_url }
        its(:core_url) { should == configuration.appliance_url }
        context "appliance_url overridden" do
          let(:override_options) {
            { :appliance_url => "https://example/api" }
          }
          it "is ignored by the configuration core_url" do
            configuration.core_url.should == "https://conjur/api"
          end
          it "is reflected in the copy core_url" do
            subject.core_url.should == "https://example/api"
          end
        end
      end
    end
  end
    
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
