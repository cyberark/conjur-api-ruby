require 'spec_helper'

describe Conjur::RoleGrant, api: :dummy do
  describe '::parse_from_json' do
    it "creates member and grantor roles" do
      rg = Conjur::RoleGrant::parse_from_json({member: 'acc:k:r', grantor: 'acc:k:g', admin_option: true}.stringify_keys, {})
      rg.member.url.should == "#{authz_host}/acc/roles/k/r"
      rg.grantor.url.should == "#{authz_host}/acc/roles/k/g"
      rg.admin_option.should == true
    end
  end
end
