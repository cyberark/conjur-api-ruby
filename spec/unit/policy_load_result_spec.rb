require 'spec_helper'
require 'conjur/policy_load_result'

# Tests the behavior of the Conjur::PolicyLoadResult class when parsing API responses.
describe Conjur::PolicyLoadResult do
  let(:data) do
    {
      "created_roles" => {
        "conjur:host:data/host-no-key" => {
          "id" => "conjur:host:data/host-no-key",
          "api_key" => nil
        },
        "conjur:host:data/host-with-key" => {
          "id" => "conjur:host:data/host-with-key",
          "api_key" => "12345"
        }
      },
      "version" => 1
    }
  end

  subject { described_class.new(data) }

  describe "#created_roles" do
    it "parses created roles with their API keys" do
      created_roles = subject.created_roles

      expect(created_roles).to include("conjur:host:data/host-no-key")
      expect(created_roles["conjur:host:data/host-no-key"]["api_key"]).to be_nil

      expect(created_roles).to include("conjur:host:data/host-with-key")
      expect(created_roles["conjur:host:data/host-with-key"]["api_key"]).to eq("12345")
    end

    it "returns nil if created_roles is missing" do
      data.delete("created_roles")
      expect(subject.created_roles).to be_nil
    end

    it "returns an empty hash if created_roles is empty" do
      data["created_roles"] = {}
      expect(subject.created_roles).to eq({})
    end

    it "handles multiple roles with mixed api_key states, including null and missing keys" do
      data["created_roles"] = {
        "conjur:host:data/host-no-key" => {
          "id" => "conjur:host:data/host-no-key",
          "api_key" => nil
        },
        "conjur:host:data/host-with-key" => {
          "id" => "conjur:host:data/host-with-key",
          "api_key" => "valid_api_key"
        },
        "conjur:host:data/host-missing-key" => {
          "id" => "conjur:host:data/host-missing-key"
        },
        "conjur:host:data/host-another-no-key" => {
          "id" => "conjur:host:data/host-another-no-key",
          "api_key" => nil
        }
      }

      created_roles = subject.created_roles

      # Check the role with a null API key
      host_no_key = created_roles["conjur:host:data/host-no-key"]
      expect(host_no_key).not_to be_nil
      expect(host_no_key["id"]).to eq("conjur:host:data/host-no-key")
      expect(host_no_key["api_key"]).to be_nil

      # Check the role with a valid API key
      host_with_key = created_roles["conjur:host:data/host-with-key"]
      expect(host_with_key).not_to be_nil
      expect(host_with_key["id"]).to eq("conjur:host:data/host-with-key")
      expect(host_with_key["api_key"]).to eq("valid_api_key")

      # Check the role with a missing API key field
      host_missing_key = created_roles["conjur:host:data/host-missing-key"]
      expect(host_missing_key).not_to be_nil
      expect(host_missing_key["id"]).to eq("conjur:host:data/host-missing-key")
      expect(host_missing_key["api_key"]).to be_nil

      # Check another role with a null API key
      another_no_key = created_roles["conjur:host:data/host-another-no-key"]
      expect(another_no_key).not_to be_nil
      expect(another_no_key["id"]).to eq("conjur:host:data/host-another-no-key")
      expect(another_no_key["api_key"]).to be_nil
    end
  end

  describe "#version" do
    it "parses the version of the policy" do
      expect(subject.version).to eq(1)
    end

    it "returns nil if version is missing" do
      data.delete("version")
      expect(subject.version).to be_nil
    end
  end
end