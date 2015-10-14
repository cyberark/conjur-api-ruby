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
      let(:ssl_certificate){ "-----BEGIN CERTIFICATE-----\nfoo\n-----END CERTIFICATE-----\n" }
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
      let(:ssl_certificate){ "-----BEGIN CERTIFICATE----- MIIDUTCCAjmgAwIBAgIJAO4Lf1Rf2cciMA0GCSqGSIb3DQEBBQUAMDMxMTAvBgNV BAMTKGVjMi01NC05MS0yNDYtODQuY29tcHV0ZS0xLmFtYXpvbmF3cy5jb20wHhcN MTQxMDA4MjEwNTA5WhcNMjQxMDA1MjEwNTA5WjAzMTEwLwYDVQQDEyhlYzItNTQt OTEtMjQ2LTg0LmNvbXB1dGUtMS5hbWF6b25hd3MuY29tMIIBIjANBgkqhkiG9w0B AQEFAAOCAQ8AMIIBCgKCAQEAx+OFANXNEYNsMR3Uvg4/72VG3LZO8yxrYaYzc3FZ NN3NpIOCZvRTC5S+OawsdEljHwfhdVoXdWNKgVJakSxsAnnaj11fA6XpfN60o6Fk i4q/BqwqgeNJjKAlElFsNz2scWFWRe49NHlj9qaq/yWZ8Cn0IeHy8j8F+jMek4zt dCSxVEayVG/k8RFmYCcluQc/1LuCjPiFwJU43AGkO+yvmOuYGivsNKY+54yuEZqF VDsjAjMsYXxgLx9y1F7Rq3CfeqY6IajR7pmmRup8/D9NyyyQuIML83mjTSvo0UYu rkdXPObd/m6gumscvXMl6SoJ5IPItvTA42MZqTaNzimF0QIDAQABo2gwZjBkBgNV HREEXTBbgglsb2NhbGhvc3SCBmNvbmp1coIcY29uanVyLW1hc3Rlci5pdHAuY29u anVyLm5ldIIoZWMyLTU0LTkxLTI0Ni04NC5jb21wdXRlLTEuYW1hem9uYXdzLmNv bTANBgkqhkiG9w0BAQUFAAOCAQEANk7P3ZEZHLgiTrLG13VAkm33FAvFzRG6akx1 jgNeRDgSaxRtrfJq3mnhsmD6hdvv+e6prPCFOjeEDheyCZyQDESdVEJBwytHVjnH dbvgMRaPm6OO8CyRyNjg3YcC36T//oQKOdAXXEcrtd0QbelBDYlKA7smJtznfhAb XypVdeS/6I4qvJi3Ckp5sQ1GszYhVXAvEeWeY59WwsTWYHLkzss9QShnigPyo3LY ZA5JVXofYi9DJ6VexP7sJNhCMrY2WnMpPcAOB9T7a6lcoXj6mWxvFys0xDIEOnc6 NGb+d47blphUKRZMAUZgYgFfMfmlyu1IXj03J8AuKtIMEwkXAA== -----END CERTIFICATE----- " }
        let(:actual_certificate) {
          <<-CERT
-----BEGIN CERTIFICATE-----
MIIDUTCCAjmgAwIBAgIJAO4Lf1Rf2cciMA0GCSqGSIb3DQEBBQUAMDMxMTAvBgNV
BAMTKGVjMi01NC05MS0yNDYtODQuY29tcHV0ZS0xLmFtYXpvbmF3cy5jb20wHhcN
MTQxMDA4MjEwNTA5WhcNMjQxMDA1MjEwNTA5WjAzMTEwLwYDVQQDEyhlYzItNTQt
OTEtMjQ2LTg0LmNvbXB1dGUtMS5hbWF6b25hd3MuY29tMIIBIjANBgkqhkiG9w0B
AQEFAAOCAQ8AMIIBCgKCAQEAx+OFANXNEYNsMR3Uvg4/72VG3LZO8yxrYaYzc3FZ
NN3NpIOCZvRTC5S+OawsdEljHwfhdVoXdWNKgVJakSxsAnnaj11fA6XpfN60o6Fk
i4q/BqwqgeNJjKAlElFsNz2scWFWRe49NHlj9qaq/yWZ8Cn0IeHy8j8F+jMek4zt
dCSxVEayVG/k8RFmYCcluQc/1LuCjPiFwJU43AGkO+yvmOuYGivsNKY+54yuEZqF
VDsjAjMsYXxgLx9y1F7Rq3CfeqY6IajR7pmmRup8/D9NyyyQuIML83mjTSvo0UYu
rkdXPObd/m6gumscvXMl6SoJ5IPItvTA42MZqTaNzimF0QIDAQABo2gwZjBkBgNV
HREEXTBbgglsb2NhbGhvc3SCBmNvbmp1coIcY29uanVyLW1hc3Rlci5pdHAuY29u
anVyLm5ldIIoZWMyLTU0LTkxLTI0Ni04NC5jb21wdXRlLTEuYW1hem9uYXdzLmNv
bTANBgkqhkiG9w0BAQUFAAOCAQEANk7P3ZEZHLgiTrLG13VAkm33FAvFzRG6akx1
jgNeRDgSaxRtrfJq3mnhsmD6hdvv+e6prPCFOjeEDheyCZyQDESdVEJBwytHVjnH
dbvgMRaPm6OO8CyRyNjg3YcC36T//oQKOdAXXEcrtd0QbelBDYlKA7smJtznfhAb
XypVdeS/6I4qvJi3Ckp5sQ1GszYhVXAvEeWeY59WwsTWYHLkzss9QShnigPyo3LY
ZA5JVXofYi9DJ6VexP7sJNhCMrY2WnMpPcAOB9T7a6lcoXj6mWxvFys0xDIEOnc6
NGb+d47blphUKRZMAUZgYgFfMfmlyu1IXj03J8AuKtIMEwkXAA==
-----END CERTIFICATE-----
CERT
        }
      let(:cert){ double('cert') }

      before do
        expect(OpenSSL::X509::Certificate).to receive(:new).with(actual_certificate).at_least(:once).and_return cert
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

    context 'with two certificates in a string' do
      let(:cert_file) { nil }
      let(:ssl_certificate) do
        """-----BEGIN CERTIFICATE-----
MIIDPjCCAiagAwIBAgIVAKW1gdmOFrXt6xB0iQmYQ4z8Pf+kMA0GCSqGSIb3DQEB
CwUAMD0xETAPBgNVBAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDAS
BgNVBAMTC2N1a2UtbWFzdGVyMB4XDTE1MTAwNzE2MzAwNloXDTI1MTAwNDE2MzAw
NlowFjEUMBIGA1UEAwwLY3VrZS1tYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IB
DwAwggEKAoIBAQC9e8bGIHOLOypKA4lsLcAOcDLAq+ICuVxn9Vg0No0m32Ok/K7G
uEGtlC8RidObntblUwqdX2uP7mqAQm19j78UTl1KT97vMmmFrpVZ7oQvEm1FUq3t
FBmJglthJrSbpdZjLf7a7eL1NnunkfBdI1DK9QL9ndMjNwZNFbXhld4fC5zuSr/L
PxawSzTEsoTaB0Nw0DdRowaZgrPxc0hQsrj9OF20gTIJIYO7ctZzE/JJchmBzgI4
CdfAYg7zNS+0oc0ylV0CWMerQtLICI6BtiQ482bCuGYJ00NlDcdjd3w+A2cj7PrH
wH5UhtORL5Q6i9EfGGUCDbmfpiVD9Bd3ukbXAgMBAAGjXDBaMA4GA1UdDwEB/wQE
AwIFoDAdBgNVHQ4EFgQU2jmj7l5rSw0yVb/vlWAYkK/YBwkwKQYDVR0RBCIwIIIL
Y3VrZS1tYXN0ZXKCCWxvY2FsaG9zdIIGY29uanVyMA0GCSqGSIb3DQEBCwUAA4IB
AQBCepy6If67+sjuVnT9NGBmjnVaLa11kgGNEB1BZQnvCy0IN7gpLpshoZevxYDR
3DnPAetQiZ70CSmCwjL4x6AVxQy59rRj0Awl9E1dgFTYI3JxxgLsI9ePdIRVEPnH
dhXqPY5ZIZhvdHlLStjsXX7laaclEtMeWfSzxe4AmP/Sm/er4ks0gvLQU6/XJNIu
RnRH59ZB1mZMsIv9Ii790nnioYFR54JmQu1JsIib77ZdSXIJmxAtraJSTLcZbU1E
+SM3XCE423Xols7onyluMYDy3MCUTFwoVMRBcRWCAk5gcv6XvZDfLi6Zwdne6x3Y
bGenr4vsPuSFsycM03/EcQDT
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIDhzCCAm+gAwIBAgIJAJnsrJ1+j9MhMA0GCSqGSIb3DQEBCwUAMD0xETAPBgNV
BAoTCGN1Y3VtYmVyMRIwEAYDVQQLEwlDb25qdXIgQ0ExFDASBgNVBAMTC2N1a2Ut
bWFzdGVyMB4XDTE1MTAwNzE2MzAwM1oXDTI1MTAwNDE2MzAwM1owPTERMA8GA1UE
ChMIY3VjdW1iZXIxEjAQBgNVBAsTCUNvbmp1ciBDQTEUMBIGA1UEAxMLY3VrZS1t
YXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCsuZ06Ld4JDhxZ
FcxKVxu7MTjXVv6W8pI7qFKmgr39aNqmDpKYJ1H9aM+r9zaTAeithpM4wJpVswkJ
d0RSuKdm1LOx11yHLyZ1OvlPHFhsVWdZIQZ6R9srhPYBUCMem4sHR5IAcBBX+HkR
35gaPYUl1uFV/9zCniekt92Kdta+it1WL7XinXTBURlhDawiD/kv1C9x6dICEJVe
IT/jRohmqHAoM/JSOQTthaDli3Qvu5K8XAx8UXvWVmv3eStZFVDbC4ZEueRd9KAe
4IZ5FxdpFYkPBgt2lBYeydYKRShyYrDKye1uJBDkeplNaYW4cS4mOhYuRkdKn7MH
uY/xb1lFAgMBAAGjgYkwgYYwKQYDVR0RBCIwIIILY3VrZS1tYXN0ZXKCCWxvY2Fs
aG9zdIIGY29uanVyMB0GA1UdDgQWBBRHpGF7aQbHdORYgQKDC2hV6NzEKzAfBgNV
HSMEGDAWgBRHpGF7aQbHdORYgQKDC2hV6NzEKzAMBgNVHRMEBTADAQH/MAsGA1Ud
DwQEAwIB5jANBgkqhkiG9w0BAQsFAAOCAQEAGZT9Wek1hYluIVaxu03wSKCKIJ4p
KxTHw+mLDapg1y9t3Fa/5IQQK0Bx0xGU2qWiQKjda3vdFPJWO6l6XJvsUY5Nwtm5
Gcsk8l3L/zWCrjrFTH3TdVad5E+DTwVhThelmEjw68AyM+WuOL61j0MItd9mLW74
Lv2zouj9nQBdnUBHWQ0EL/9d5cfaCVu/bFlDfYt7Yj0IzXCuaWZfJeHodU1hmqVX
BvYRjnTB2LSxfmSnkrCeFPmhE11bWVtsLIdrGIgtEMX0/s9xg58QuNnva1U3pJsW
RjvSxre4Xg2qlI9Laybb4oZ4g6DI8hRbL0VdFAsveg6SXg2RxgJcXeJUFw==
-----END CERTIFICATE-----
"""
      end

      it 'adds both to the store' do
        expect(store).to receive(:add_cert).twice
        expect(subject).to be_truthy
      end
    end
  end
end
