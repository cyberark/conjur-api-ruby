# frozen_string_literal: true

require 'spec_helper'
require 'conjur/api/policies'

describe "Conjur::API#fetch_policy", api: :dummy do
  let(:api) { Conjur::API.new_from_key('user', 'pass') }

  before do
    allow(api).to receive(:credentials).and_return('the-credentials')
  end

  it "fetches the policy as YAML by default" do
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
