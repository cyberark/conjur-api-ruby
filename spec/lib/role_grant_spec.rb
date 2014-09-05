require 'spec_helper'

describe Conjur::RoleGrant, api: :dummy do
  describe '::parse_from_json' do
    it "creates member and grantor roles" do
      rg = Conjur::RoleGrant::parse_from_json({member: 'acc:k:r', grantor: 'acc:k:g', admin_option: true}.stringify_keys, {})
      expect(rg.member.url).to eq("#{authz_host}/acc/roles/k/r")
      expect(rg.grantor.url).to eq("#{authz_host}/acc/roles/k/g")
      expect(rg.admin_option).to eq(true)
    end
  end
end
