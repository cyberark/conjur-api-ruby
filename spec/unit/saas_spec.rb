# frozen_string_literal: true

require 'spec_helper'
require 'conjur/saas'

describe Conjur::Saas do
  describe ".appliance_url?" do
    it "matches a .secretsmgr SaaS hostname" do
      expect(Conjur::Saas.appliance_url?("https://myorg.secretsmgr.cyberark.cloud")).to be true
    end

    it "matches a -secretsmanager SaaS hostname" do
      expect(Conjur::Saas.appliance_url?("https://myorg-secretsmanager.dev-cyberark.cloud")).to be true
    end

    it "matches with additional subdomains before the prefix" do
      expect(Conjur::Saas.appliance_url?("https://tenant.myorg.secretsmgr.sandbox-cyberark.cloud")).to be true
    end

    it "does not match a plain appliance URL" do
      expect(Conjur::Saas.appliance_url?("https://conjur.example.com/api")).to be false
    end

    it "does not match when the scheme is not https" do
      expect(Conjur::Saas.appliance_url?("http://myorg.secretsmgr.cyberark.cloud")).to be false
    end

    it "does not match a nil url" do
      expect(Conjur::Saas.appliance_url?(nil)).to be false
    end

    it "does not raise for a malformed url and returns false" do
      expect(Conjur::Saas.appliance_url?("not a url with spaces")).to be false
    end

    it "does not match a relative or opaque url with no host" do
      expect(Conjur::Saas.appliance_url?("mailto:someone@example.com")).to be false
    end
  end
end
