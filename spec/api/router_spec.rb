# frozen_string_literal: true

require 'spec_helper'
require 'conjur/api/router'

describe Conjur::API::Router do
  before do
    allow(Conjur.configuration).to receive(:core_url).and_return('http://core.example.com')
  end

  describe ".server_info" do
    it "builds an unauthenticated resource for the info endpoint" do
      resource = Conjur::API::Router.server_info

      expect(resource.url).to eq('http://core.example.com/info')
      expect(resource.options[:headers]).not_to have_key(:authorization)
    end
  end

  describe ".server_root" do
    it "builds an unauthenticated resource for the root endpoint" do
      resource = Conjur::API::Router.server_root

      expect(resource.url).to eq('http://core.example.com/')
    end
  end

  describe ".policies_load_policy" do
    it "builds a resource with no trailing slash or query string" do
      resource = Conjur::API::Router.policies_load_policy({}, 'the-account', 'root')

      expect(resource.url).to eq('http://core.example.com/policies/the-account/policy/root')
    end
  end

  describe ".policies_dry_run_policy" do
    it "builds a resource with the dryRun query string" do
      resource = Conjur::API::Router.policies_dry_run_policy({}, 'the-account', 'root')

      expect(resource.url).to eq('http://core.example.com/policies/the-account/policy/root/?dryRun=true')
    end
  end
end
