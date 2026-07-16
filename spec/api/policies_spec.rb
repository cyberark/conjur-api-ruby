# frozen_string_literal: true

require 'spec_helper'
require 'conjur/api/policies'

describe "Conjur::API#fetch_policy", api: :dummy do
  let(:api) { Conjur::API.new_from_key('user', 'pass') }

  before do
    allow(api).to receive(:credentials).and_return('the-credentials')
  end

  it "raises FeatureNotAvailable for a SaaS appliance" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://x.secretsmgr.cyberark.cloud')

    expect { api.fetch_policy('root', account: 'the-account') }.to raise_error(Conjur::FeatureNotAvailable, /SaaS/)
  end

  it "raises FeatureNotAvailable for a server older than 1.21.1" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://conjur.example.com')
    allow(api).to receive(:server_version).and_return('1.20.0')

    expect { api.fetch_policy('root', account: 'the-account') }.to raise_error(Conjur::FeatureNotAvailable, /1\.21\.1/)
  end

  it "fetches the policy as YAML by default" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://conjur.example.com')
    allow(api).to receive(:server_version).and_return('1.21.1')

    resource = instance_double(RestClient::Resource, "policy resource")
    allow(api).to receive(:url_for)
      .with(:policies_fetch_policy, 'the-credentials', 'the-account', 'root', {})
      .and_return(resource)

    allow(resource).to receive(:get).with('Content-Type' => 'application/x-yaml').and_return(
      instance_double(RestClient::Response, "policy response", body: "- !host foo\n")
    )

    expect(api.fetch_policy('root', account: 'the-account')).to eq("- !host foo\n")
  end

  it "fetches the policy as JSON when requested" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://conjur.example.com')
    allow(api).to receive(:server_version).and_return('1.21.1')

    resource = instance_double(RestClient::Resource, "policy resource")
    allow(api).to receive(:url_for)
      .with(:policies_fetch_policy, 'the-credentials', 'the-account', 'root', { depth: 2, limit: 100 })
      .and_return(resource)

    allow(resource).to receive(:get).with('Content-Type' => 'application/json').and_return(
      instance_double(RestClient::Response, "policy response", body: '[{"id":"cucumber:host:foo"}]')
    )

    expect(
      api.fetch_policy('root', account: 'the-account', return_json: true, depth: 2, limit: 100)
    ).to eq('[{"id":"cucumber:host:foo"}]')
  end
end

describe "Conjur::API#dry_run_policy", api: :dummy do
  let(:api) { Conjur::API.new_from_key('user', 'pass') }

  before do
    allow(api).to receive(:credentials).and_return('the-credentials')
  end

  it "raises FeatureNotAvailable for a SaaS appliance" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://x.secretsmgr.cyberark.cloud')

    expect { api.dry_run_policy('root', 'policy body', account: 'the-account') }.to raise_error(Conjur::FeatureNotAvailable, /SaaS/)
  end

  it "raises FeatureNotAvailable for a server older than 1.21.1" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://conjur.example.com')
    allow(api).to receive(:server_version).and_return('1.20.0')

    expect { api.dry_run_policy('root', 'policy body', account: 'the-account') }.to raise_error(Conjur::FeatureNotAvailable, /1\.21\.1/)
  end

  it "validates a policy load without applying it, defaulting to POST" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://conjur.example.com')
    allow(api).to receive(:server_version).and_return('1.21.1')

    resource = instance_double(RestClient::Resource, "policy resource")
    allow(api).to receive(:url_for)
      .with(:policies_dry_run_policy, 'the-credentials', 'the-account', 'root')
      .and_return(resource)

    allow(resource).to receive(:post).with('policy body').and_return(
      '{"status":"Valid YAML","created":{"items":[]},"updated":{"before":{"items":[]},"after":{"items":[]}},"deleted":{"items":[]}}'
    )

    result = api.dry_run_policy('root', 'policy body', account: 'the-account')

    expect(result['status']).to eq('Valid YAML')
  end

  it "supports POLICY_METHOD_PUT" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://conjur.example.com')
    allow(api).to receive(:server_version).and_return('1.21.1')

    resource = instance_double(RestClient::Resource, "policy resource")
    allow(api).to receive(:url_for)
      .with(:policies_dry_run_policy, 'the-credentials', 'the-account', 'root')
      .and_return(resource)

    allow(resource).to receive(:put).with('policy body').and_return(
      '{"status":"Valid YAML"}'
    )

    result = api.dry_run_policy(
      'root', 'policy body', account: 'the-account', method: Conjur::API::POLICY_METHOD_PUT
    )

    expect(result['status']).to eq('Valid YAML')
  end

  it "reports invalid policy YAML instead of raising" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://conjur.example.com')
    allow(api).to receive(:server_version).and_return('1.21.1')

    resource = instance_double(RestClient::Resource, "policy resource")
    allow(api).to receive(:url_for)
      .with(:policies_dry_run_policy, 'the-credentials', 'the-account', 'root')
      .and_return(resource)

    response_body = '{"status":"Invalid YAML","errors":[{"line":1,"column":10,"message":"bad yaml"}]}'
    response = instance_double(RestClient::Response, "error response", body: response_body, code: 422)
    exception = RestClient::UnprocessableEntity.new(response)
    allow(exception).to receive(:response).and_return(response)
    allow(resource).to receive(:post).with('- !group [invalid').and_raise(exception)

    result = api.dry_run_policy('root', '- !group [invalid', account: 'the-account')

    expect(result['status']).to eq('Invalid YAML')
    expect(result['errors'].first['message']).to eq('bad yaml')
  end

  it "raises for other error responses instead of returning them as a result" do
    allow(Conjur.configuration).to receive(:appliance_url).and_return('https://conjur.example.com')
    allow(api).to receive(:server_version).and_return('1.21.1')

    resource = instance_double(RestClient::Resource, "policy resource")
    allow(api).to receive(:url_for)
      .with(:policies_dry_run_policy, 'the-credentials', 'the-account', 'root')
      .and_return(resource)

    response = instance_double(RestClient::Response, "error response", body: '{"error":"forbidden"}', code: 403)
    exception = RestClient::Forbidden.new(response)
    allow(exception).to receive(:response).and_return(response)
    allow(resource).to receive(:post).with('policy body').and_raise(exception)

    expect {
      api.dry_run_policy('root', 'policy body', account: 'the-account')
    }.to raise_error(RestClient::Forbidden)
  end
end
