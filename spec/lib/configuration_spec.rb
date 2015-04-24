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

  describe "apply_cert_config!" do
    subject{ Conjur.configuration.apply_cert_config! }

    let(:store){ double('default store') }


    before do
      stub_const 'OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE', store
      allow_any_instance_of(Conjur::Configuration).to receive(:ssl_certificate).and_return ssl_certificate
      allow_any_instance_of(Conjur::Configuration).to receive(:cert_file).and_return cert_file

    end

    context "when neither cert_file or ssl_certificate is present" do
      let(:cert_file){ nil }
      let(:ssl_certificate){ nil }

      it 'does nothing to the store' do
        expect(store).to_not receive(:add_file)
        expect(store).to_not receive(:add_cert)
        expect(subject).to be_falsey
      end
    end

    context 'when both are given' do
      let(:cert_file){ '/path/to/cert.pem' }
      let(:ssl_certificate){ 'certificate contents' }
      let(:cert){ double('certificate') }
      it 'calls store.add_cert with a certificate created from ssl_certificate' do
        expect(OpenSSL::X509::Certificate).to receive(:new).with(ssl_certificate).once.and_return cert
        expect(store).to receive(:add_cert).once.with(cert)
        expect(subject).to be_truthy
      end
    end

    context 'when cert_file is given and ssl_certificate is not' do
      let(:cert_file){ '/path/to/cert.pem' }
      let(:ssl_certificate){ nil }
      it 'calls store.add_file with cert_file' do
        expect(store).to receive(:add_file).with(cert_file).once
        expect(subject).to be_truthy
      end
    end

    context 'when ssl_certificate is given' do
      let(:cert_file){ nil }
      let(:ssl_certificate){ 'certificate contents' }
      let(:cert){ double('cert') }

      before do
        expect(OpenSSL::X509::Certificate).to receive(:new).with(ssl_certificate).at_least(:once).and_return cert
      end

      it 'calls store.add_cert with a certificate created from ssl_certificate' do
        expect(store).to receive(:add_cert).with(cert).once
        expect(subject).to be_truthy
      end

      it 'rescues from a StoreError with message "cert already in hash tabble"' do
        expect(store).to receive(:add_cert).with(cert).once.and_raise(OpenSSL::X509::StoreError.new('cert already in hash table'))
        expect(subject).to be_truthy
      end


      it 'does not rescue from other exceptions' do
        expect(store).to receive(:add_cert).with(cert).once.and_raise(OpenSSL::X509::StoreError.new('some other message'))
        expect{subject}.to raise_exception
        expect(store).to receive(:add_cert).with(cert).once.and_raise(ArgumentError.new('bad news'))
        expect{subject}.to raise_exception
      end
    end

    context 'when given a store argument' do
      let(:cert_file){ '/path/to/cert.pem' }
      let(:ssl_certificate){ nil }
      let(:alt_store){ double('alt store') }
      subject{ Conjur.configuration.apply_cert_config! alt_store }

      it 'uses that store instead' do
        expect(alt_store).to receive(:add_file).with(cert_file).once
        expect(subject).to be_truthy
      end
    end

  end
end
