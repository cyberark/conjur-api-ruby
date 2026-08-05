# frozen_string_literal: true

require 'spec_helper'
require 'cgi'
require 'conjur/api/router'

describe Conjur::API, api: :dummy do
  let(:identity)   { 'host/data/test/gcp-apps/test-app' }
  let(:gcp_jwt)    { 'eyJhbGciOiJSUzI1NiJ9.gcp-payload.sig' }
  let(:raw_token)  { { 'protected' => 'p', 'payload' => 'pl', 'signature' => 's' } }

  describe '.new_from_gcp' do
    it 'returns an API instance with a GCPAuthenticator' do
      allow(Conjur::API).to receive(:authenticate_gcp).and_return(raw_token)
      api_instance = Conjur::API.new_from_gcp(identity, account: account)
      expect(api_instance).to be_a(Conjur::API)
      expect(api_instance.authenticator).to be_a(Conjur::API::GCPAuthenticator)
    end
  end

  describe '.authenticate_gcp' do
    let(:resource) { double('resource') }

    before do
      allow(Conjur::API).to receive(:url_for)
        .with(:authn_gcp_authenticate, account)
        .and_return(resource)
      allow(resource).to receive(:post)
        .with("jwt=#{CGI.escape(gcp_jwt)}", content_type: 'application/x-www-form-urlencoded')
        .and_return(raw_token.to_json)
    end

    context 'with a pre-supplied JWT' do
      it 'returns a parsed token without calling the metadata service' do
        expect(Conjur::API).not_to receive(:fetch_gcp_jwt)
        token = Conjur::API.authenticate_gcp(identity, account: account, jwt: gcp_jwt)
        expect(token).to eq(raw_token)
      end
    end

    context 'without a pre-supplied JWT' do
      it 'fetches from the metadata service' do
        allow(Conjur::API).to receive(:fetch_gcp_jwt).and_return(gcp_jwt)
        token = Conjur::API.authenticate_gcp(identity, account: account)
        expect(token).to eq(raw_token)
      end
    end

    it 'raises ArgumentError when identity is empty' do
      expect { Conjur::API.authenticate_gcp('', account: account) }
        .to raise_error(ArgumentError, /identity is required/)
    end
  end

  describe 'GCPAuthenticator#refresh_token' do
    context 'with a pre-supplied JWT' do
      subject(:authenticator) do
        Conjur::API::GCPAuthenticator.new(account, identity, jwt: gcp_jwt)
      end

      it 'passes the stored JWT to authenticate_gcp' do
        expect(Conjur::API).to receive(:authenticate_gcp)
          .with(identity,
                account: account,
                jwt: gcp_jwt,
                gcp_identity_url: Conjur::API::GCPAuthenticator::DEFAULT_METADATA_URL)
          .and_return(raw_token)
        expect(authenticator.refresh_token).to eq(raw_token)
      end
    end

    context 'without a pre-supplied JWT' do
      subject(:authenticator) do
        Conjur::API::GCPAuthenticator.new(account, identity)
      end

      it 'passes nil jwt to authenticate_gcp (which then calls metadata service)' do
        expect(Conjur::API).to receive(:authenticate_gcp)
          .with(identity,
                account: account,
                jwt: nil,
                gcp_identity_url: Conjur::API::GCPAuthenticator::DEFAULT_METADATA_URL)
          .and_return(raw_token)
        expect(authenticator.refresh_token).to eq(raw_token)
      end
    end
  end

  describe '.gcp_audience' do
    it 'strips a leading host/ and rebuilds the conjur audience' do
      expect(Conjur::API.send(:gcp_audience, account, 'host/data/app'))
        .to eq("conjur/#{account}/host/data/app")
    end

    it 'assumes a host identity when the host/ prefix is absent' do
      expect(Conjur::API.send(:gcp_audience, account, 'data/app'))
        .to eq("conjur/#{account}/host/data/app")
    end
  end
end

describe Conjur::API::Router do
  let(:account)    { 'myaccount' }

  before do
    allow(Conjur.configuration).to receive(:core_url).and_return('https://conjur.example.com')
    allow(Conjur.configuration).to receive(:rest_client_options).and_return({})
  end

  describe '#authn_gcp_authenticate' do
    subject { described_class.authn_gcp_authenticate(account) }

    it 'returns a RestClient::Resource' do
      expect(subject).to be_a(RestClient::Resource)
    end

    it 'builds the correct URL using the serviceless authn-gcp path' do
      expect(subject.url).to end_with('/authn-gcp/myaccount/authenticate')
    end
  end
end
