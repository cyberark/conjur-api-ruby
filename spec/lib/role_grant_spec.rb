require 'spec_helper'

describe Conjur::RoleGrant, api: :dummy do
  describe '::parse_from_json' do
    it "creates role, member and grantor roles" do
      rg = Conjur::RoleGrant::parse_from_json({role: 'acc:k:r', member: 'acc:k:m', grantor: 'acc:k:g', admin_option: true}.stringify_keys, {})
      expect(rg.role.url).to eq("#{authz_host}/acc/roles/k/r")
      expect(rg.member.url).to eq("#{authz_host}/acc/roles/k/m")
      expect(rg.grantor.url).to eq("#{authz_host}/acc/roles/k/g")
      expect(rg.admin_option).to eq(true)
    end
  end
end
