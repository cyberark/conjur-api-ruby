require 'spec_helper'

describe Conjur::Configuration do
  before {
    Conjur.configuration = Conjur::Configuration.new
  }
  after(:all) do
    # reset the configuration so it doesn't clobber other tests
    Conjur.configuration = Conjur::Configuration.new
  end

  subject(:configuration) { Conjur.configuration }
  context "thread-local behavior" do
    it "can swap the Configuration in a new thread" do
      original = Conjur.configuration
      c = Conjur::Configuration.new
      Thread.new do
        Thread.current[:conjur_configuration] = :foo
        Conjur.with_configuration c do
          expect(Conjur.configuration).to eq(c)
        end
        expect(Thread.current[:conjur_configuration]).to eq(:foo)
      end.join
      expect(Conjur.configuration).to eq(original)
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

        describe '#account' do
          subject { super().account }
          it { is_expected.to eq(configuration.account) }
        end

        describe '#appliance_url' do
          subject { super().appliance_url }
          it { is_expected.to eq(configuration.appliance_url) }
        end

        describe '#core_url' do
          subject { super().core_url }
          it { is_expected.to eq(configuration.appliance_url) }
        end

        context "appliance_url overridden" do
          let(:override_options) {
            { :appliance_url => "https://example/api" }
          }
          it "is ignored by the configuration core_url" do
            expect(configuration.core_url).to eq("https://conjur/api")
          end
          it "is reflected in the copy core_url" do
            expect(subject.core_url).to eq("https://example/api")
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
      describe '#env' do
        subject { super().env }
        it { is_expected.to eq("production") }
      end
    end
    context "default stack" do
      describe '#stack' do
        subject { super().stack }
        it { is_expected.to eq("v4") }
      end
    end
    describe 'authn_url' do
      before {
        allow_any_instance_of(Conjur::Configuration).to receive(:account).and_return "the-account"
      }
      context "with appliance_url" do
        before {
          allow_any_instance_of(Conjur::Configuration).to receive(:appliance_url).and_return "http://example.com"
        }

        describe '#authn_url' do
          subject { super().authn_url }
          it { is_expected.to eq("http://example.com/authn") }
        end
      end
      context "without appliance_url" do
        describe '#authn_url' do
          subject { super().authn_url }
          it { is_expected.to eq("https://authn-the-account-conjur.herokuapp.com") }
        end
      end
    end
    describe 'authz_url' do
      before {
        allow_any_instance_of(Conjur::Configuration).to receive(:account).and_return "the-account"
      }
      context "with appliance_url" do
        before {
          allow_any_instance_of(Conjur::Configuration).to receive(:appliance_url).and_return "http://example.com"
        }

        describe '#authz_url' do
          subject { super().authz_url }
          it { is_expected.to eq("http://example.com/authz") }
        end
      end
      context "without appliance_url" do
        describe '#authz_url' do
          subject { super().authz_url }
          it { is_expected.to eq("https://authz-v4-conjur.herokuapp.com") }
        end
        context "with specific stack" do
          before { allow_any_instance_of(Conjur::Configuration).to receive(:stack).and_return "the-stack" }

          describe '#authz_url' do
            subject { super().authz_url }
            it { is_expected.to eq("https://authz-the-stack-conjur.herokuapp.com") }
          end
        end
      end
    end
  end
  context "CONJUR_ENV = 'test'" do
    describe '#env' do
      subject { super().env }
      it { is_expected.to eq("test") }
    end
    before {
      allow_any_instance_of(Conjur::Configuration).to receive(:account).and_return "the-account"
    }
    describe 'authn_url' do
      context "with appliance_url hostname" do
        before {
          allow_any_instance_of(Conjur::Configuration).to receive(:appliance_url).and_return "http://example.com"
        }

        describe '#authn_url' do
          subject { super().authn_url }
          it { is_expected.to eq("http://example.com/authn") }
        end
      end
      context "with appliance_url hostname and non-trailing-slash path" do
        before {
          allow_any_instance_of(Conjur::Configuration).to receive(:appliance_url).and_return "http://example.com/api"
        }

        describe '#authn_url' do
          subject { super().authn_url }
          it { is_expected.to eq("http://example.com/api/authn") }
        end
      end
      context "without appliance_url" do
        describe '#authn_url' do
          subject { super().authn_url }
          it { is_expected.to eq("http://localhost:5000") }
        end
      end
    end
    describe 'authz_url' do
      context "with appliance_url" do
        before {
          allow_any_instance_of(Conjur::Configuration).to receive(:appliance_url).and_return "http://example.com/api/"
        }

        describe '#authz_url' do
          subject { super().authz_url }
          it { is_expected.to eq("http://example.com/api/authz") }
        end
      end
      context "without appliance_url" do
        describe '#authz_url' do
          subject { super().authz_url }
          it { is_expected.to eq("http://localhost:5100") }
        end
      end
    end
    describe 'core_url' do
      context "with appliance_url" do
        before {
          allow_any_instance_of(Conjur::Configuration).to receive(:appliance_url).and_return "http://example.com/api"
        }

        describe '#core_url' do
          subject { super().core_url }
          it { is_expected.to eq("http://example.com/api") }
        end
      end
      context "without appliance_url" do
        describe '#core_url' do
          subject { super().core_url }
          it { is_expected.to eq("http://localhost:5200") }
        end
      end
    end
  end
end
