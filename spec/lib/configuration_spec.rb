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
    it "core_url is not pre-cached" do
      configuration.supplied[:core_url].should_not be
    end
    it "core_url is cached after use" do
      configuration.core_url
      configuration.supplied[:core_url].should == configuration.core_url
    end
    context "and core_url fetched" do
      before { 
        configuration.core_url 
      }
      context "and duplicated" do 
        subject { configuration.clone override_options }
        let(:override_options) { Hash.new }
        its(:account) { should == configuration.account }
        its(:appliance_url) { should == configuration.appliance_url }
        its(:core_url) { should == configuration.appliance_url }
        context "core_url fetched" do
          it "is then cached in the original" do
            configuration.supplied[:core_url].should be
          end
          it "is not cached in the copy" do
            subject.supplied[:core_url].should_not be
          end
        end
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
