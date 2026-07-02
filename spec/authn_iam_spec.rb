# frozen_string_literal: true

require 'spec_helper'
require 'conjur/api/router'

describe Conjur::API, api: :dummy do
  let(:service_id) { 'prod' }
  let(:identity)   { 'host/my-app/my-role' }
  let(:raw_token)  { { 'protected' => 'p', 'payload' => 'pl', 'signature' => 's' } }
  let(:signed_headers) do
    {
      'Authorization'        => 'AWS4-HMAC-SHA256 Credential=AKIAEXAMPLE/...',
      'x-amz-date'           => '20240101T000000Z',
      'x-amz-content-sha256' => 'e3b0c44298fc1c149afbf4c8996fb924',
      'x-amz-security-token' => 'token',
      'host'                 => 'sts.amazonaws.com'
    }
  end

  describe '.new_from_iam' do
    it 'returns an API instance with an IAMAuthenticator' do
      allow(Conjur::API).to receive(:authenticate_iam).and_return(raw_token)
      api_instance = Conjur::API.new_from_iam(identity, account: account)
      expect(api_instance).to be_a(Conjur::API)
      expect(api_instance.authenticator).to be_a(Conjur::API::IAMAuthenticator)
    end
  end

  describe '.authenticate_iam' do
    let(:resource) { double('resource') }

    before do
      allow(Conjur::API).to receive(:url_for)
        .with(:authn_iam_authenticate, account, service_id, identity)
        .and_return(resource)
      allow(resource).to receive(:post)
        .with(signed_headers.to_json, content_type: 'application/json')
        .and_return(raw_token.to_json)
      allow(Conjur::API).to receive(:build_iam_signed_headers).and_return(signed_headers)
    end

    it 'returns a parsed token' do
      token = Conjur::API.authenticate_iam(identity, account: account, service_id: service_id)
      expect(token).to eq(raw_token)
    end

    it 'raises ArgumentError when identity is empty' do
      expect { Conjur::API.authenticate_iam('', account: account) }
        .to raise_error(ArgumentError, /identity is required/)
    end

    it 'raises ArgumentError when service_id is empty' do
      expect { Conjur::API.authenticate_iam(identity, account: account, service_id: '') }
        .to raise_error(ArgumentError, /service_id is required/)
    end

    it 'raises LoadError when aws-sdk-core is unavailable' do
      allow(Conjur::API).to receive(:require).with('aws-sdk-core').and_raise(LoadError)
      expect { Conjur::API.authenticate_iam(identity, account: account) }
        .to raise_error(LoadError, /aws-sdk-core/)
    end
  end

  describe 'IAMAuthenticator#refresh_token' do
    subject(:authenticator) do
      Conjur::API::IAMAuthenticator.new(account, service_id, identity)
    end

    it 'delegates to authenticate_iam with stored credentials' do
      expect(Conjur::API).to receive(:authenticate_iam)
        .with(identity,
              account: account,
              service_id: service_id,
              aws_region: Conjur::API::IAMAuthenticator::DEFAULT_REGION)
        .and_return(raw_token)
      expect(authenticator.refresh_token).to eq(raw_token)
    end
  end
end

describe Conjur::API::Router do
  let(:account)    { 'myaccount' }
  let(:service_id) { 'prod' }
  let(:identity)   { 'host/my-app/my-role' }

  before do
    allow(Conjur.configuration).to receive(:core_url).and_return('https://conjur.example.com')
    allow(Conjur.configuration).to receive(:rest_client_options).and_return({})
  end

  describe '#authn_iam_authenticate' do
    subject { described_class.authn_iam_authenticate(account, service_id, identity) }

    it 'returns a RestClient::Resource' do
      expect(subject).to be_a(RestClient::Resource)
    end

    it 'builds the correct URL' do
      expect(subject.url).to end_with('/authn-iam/prod/myaccount/host%2Fmy-app%2Fmy-role/authenticate')
    end
  end
end
