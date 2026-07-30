# frozen_string_literal: true

require 'spec_helper'
require 'cgi'
require 'conjur/api/router'

describe Conjur::API, api: :dummy do
  let(:service_id) { 'my-azure-service' }
  let(:identity)   { 'host/my-app/azure-host' }
  let(:azure_jwt)  { 'eyJhbGciOiJSUzI1NiJ9.azure-payload.sig' }
  let(:raw_token)  { { 'protected' => 'p', 'payload' => 'pl', 'signature' => 's' } }

  describe '.new_from_azure' do
    it 'returns an API instance with an AzureAuthenticator' do
      allow(Conjur::API).to receive(:authenticate_azure).and_return(raw_token)
      api_instance = Conjur::API.new_from_azure(service_id, identity, account: account)
      expect(api_instance).to be_a(Conjur::API)
      expect(api_instance.authenticator).to be_a(Conjur::API::AzureAuthenticator)
    end
  end

  describe '.authenticate_azure' do
    let(:resource) { double('resource') }

    before do
      allow(Conjur::API).to receive(:url_for)
        .with(:authn_azure_authenticate, account, service_id, identity)
        .and_return(resource)
      allow(resource).to receive(:post)
        .with("jwt=#{CGI.escape(azure_jwt)}", content_type: 'application/x-www-form-urlencoded')
        .and_return(raw_token.to_json)
      allow(Conjur::API).to receive(:fetch_azure_jwt).and_return(azure_jwt)
    end

    it 'returns a parsed token' do
      token = Conjur::API.authenticate_azure(service_id, identity, account: account)
      expect(token).to eq(raw_token)
    end

    it 'raises ArgumentError when service_id is empty' do
      expect { Conjur::API.authenticate_azure('', identity, account: account) }
        .to raise_error(ArgumentError, /service_id is required/)
    end

    it 'raises ArgumentError when identity is empty' do
      expect { Conjur::API.authenticate_azure(service_id, '', account: account) }
        .to raise_error(ArgumentError, /identity is required/)
    end
  end

  describe 'AzureAuthenticator#refresh_token' do
    subject(:authenticator) do
      Conjur::API::AzureAuthenticator.new(account, service_id, identity)
    end

    it 'delegates to authenticate_azure with stored credentials' do
      expect(Conjur::API).to receive(:authenticate_azure)
        .with(service_id, identity,
              account: account,
              resource_uri: Conjur::API::AzureAuthenticator::DEFAULT_RESOURCE,
              client_id: nil,
              imds_base_url: Conjur::API::AzureAuthenticator::DEFAULT_IMDS_BASE,
              imds_api_version: Conjur::API::AzureAuthenticator::DEFAULT_IMDS_VER)
        .and_return(raw_token)
      expect(authenticator.refresh_token).to eq(raw_token)
    end
  end
end

describe Conjur::API::Router do
  let(:account)    { 'myaccount' }
  let(:service_id) { 'my-service' }
  let(:identity)   { 'host/my-app/azure-host' }

  before do
    allow(Conjur.configuration).to receive(:core_url).and_return('https://conjur.example.com')
    allow(Conjur.configuration).to receive(:rest_client_options).and_return({})
  end

  describe '#authn_azure_authenticate' do
    subject { described_class.authn_azure_authenticate(account, service_id, identity) }

    it 'returns a RestClient::Resource' do
      expect(subject).to be_a(RestClient::Resource)
    end

    it 'builds the correct URL' do
      expect(subject.url).to end_with('/authn-azure/my-service/myaccount/host%2Fmy-app%2Fazure-host/authenticate')
    end
  end
end
