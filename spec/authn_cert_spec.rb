# frozen_string_literal: true

require 'spec_helper'
require 'openssl'
require 'tempfile'
require 'conjur/api/router'

# Generate once for the entire spec file — RSA key generation is expensive.
TEST_KEY = OpenSSL::PKey::RSA.new(512)
TEST_CERT = OpenSSL::X509::Certificate.new.tap do |c|
  c.subject = c.issuer = OpenSSL::X509::Name.parse('/CN=test')
  c.not_before = Time.now - 1
  c.not_after  = Time.now + 3600
  c.public_key = TEST_KEY.public_key
  c.serial     = 1
  c.sign(TEST_KEY, OpenSSL::Digest::SHA256.new)
end

describe Conjur::API, api: :dummy do
  let(:service_id) { 'my-service' }
  let(:host_id)    { 'host/workloads/vm-01' }

  let(:key)  { TEST_KEY }
  let(:cert) { TEST_CERT }

  let(:raw_token) { { 'protected' => 'p', 'payload' => 'pl', 'signature' => 's' } }

  describe '.new_from_cert' do
    it 'returns an API instance with a CertAuthenticator' do
      api_instance = Conjur::API.new_from_cert(service_id, cert, key, account: account)
      expect(api_instance).to be_a(Conjur::API)
      expect(api_instance.authenticator).to be_a(Conjur::API::CertAuthenticator)
    end

    it 'accepts file paths for cert and key' do
      cert_file = Tempfile.new(['cert', '.pem'])
      key_file  = Tempfile.new(['key', '.pem'])
      begin
        cert_file.write(cert.to_pem)
        key_file.write(key.to_pem)
        cert_file.close
        key_file.close

        api_instance = Conjur::API.new_from_cert(service_id, cert_file.path, key_file.path,
                                                  account: account)
        expect(api_instance.authenticator).to be_a(Conjur::API::CertAuthenticator)
      ensure
        cert_file.unlink
        key_file.unlink
      end
    end

    it 'accepts PEM strings for cert and key' do
      api_instance = Conjur::API.new_from_cert(service_id, cert.to_pem, key.to_pem,
                                                account: account)
      expect(api_instance.authenticator).to be_a(Conjur::API::CertAuthenticator)
    end
  end

  describe '.authenticate_cert' do
    let(:resource) { double('resource') }

    before do
      allow(Conjur::API).to receive(:url_for)
        .with(:authn_cert_authenticate, account, service_id, host_id, anything)
        .and_return(resource)
      allow(resource).to receive(:post).with('').and_return(raw_token.to_json)
    end

    it 'returns a parsed token' do
      token = Conjur::API.authenticate_cert(service_id, cert, key,
                                             account: account, host_id: host_id)
      expect(token).to eq(raw_token)
    end
  end

  describe '.authenticate_cert (SPIFFE mode)' do
    let(:resource) { double('resource') }

    before do
      allow(Conjur::API).to receive(:url_for)
        .with(:authn_cert_authenticate, account, service_id, nil, anything)
        .and_return(resource)
      allow(resource).to receive(:post).with('').and_return(raw_token.to_json)
    end

    it 'returns a parsed token without host_id' do
      token = Conjur::API.authenticate_cert(service_id, cert, key, account: account)
      expect(token).to eq(raw_token)
    end
  end

  describe 'CertAuthenticator#refresh_token' do
    subject(:authenticator) do
      Conjur::API::CertAuthenticator.new(account, service_id, cert, key, host_id)
    end

    it 'calls authenticate_cert with the stored credentials' do
      expect(Conjur::API).to receive(:authenticate_cert)
        .with(service_id, cert, key, account: account, host_id: host_id)
        .and_return(raw_token)
      expect(authenticator.refresh_token).to eq(raw_token)
    end
  end

  describe 'CertAuthenticator (SPIFFE mode)' do
    subject(:authenticator) do
      Conjur::API::CertAuthenticator.new(account, service_id, cert, key)
    end

    it 'calls authenticate_cert without host_id' do
      expect(Conjur::API).to receive(:authenticate_cert)
        .with(service_id, cert, key, account: account, host_id: nil)
        .and_return(raw_token)
      expect(authenticator.refresh_token).to eq(raw_token)
    end
  end
end

describe Conjur::API::Router do
  let(:account)    { 'myaccount' }
  let(:service_id) { 'my-service' }
  let(:cert)       { double('cert') }
  let(:key)        { double('key') }
  let(:cert_opts)  { { ssl_client_cert: cert, ssl_client_key: key } }

  before do
    allow(Conjur.configuration).to receive(:core_url).and_return('https://conjur.example.com')
    allow(Conjur.configuration).to receive(:create_rest_client_options) do |opts|
      { ssl_cert_store: OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE }.merge(opts)
    end
  end

  describe '#authn_cert_authenticate' do
    context 'with host_id (request mode)' do
      subject { described_class.authn_cert_authenticate(account, service_id, 'host/vm-01', cert_opts) }

      it 'returns a RestClient::Resource' do
        expect(subject).to be_a(RestClient::Resource)
      end

      it 'builds the correct URL' do
        expect(subject.url).to end_with('/authn-cert/my-service/myaccount/host%2Fvm-01/authenticate')
      end
    end

    context 'without host_id (SPIFFE mode)' do
      subject { described_class.authn_cert_authenticate(account, service_id, nil, cert_opts) }

      it 'builds the correct URL without host segment' do
        expect(subject.url).to end_with('/authn-cert/my-service/myaccount/authenticate')
      end
    end

    context 'with a service_id containing special characters' do
      subject { described_class.authn_cert_authenticate(account, 'svc/my service', nil, cert_opts) }

      it 'URL-encodes the service_id' do
        expect(subject.url).to end_with('/authn-cert/svc%2Fmy%20service/myaccount/authenticate')
      end
    end
  end
end
