module Conjur
  RoleGrant = Struct.new(:member, :grantor, :admin_option) do
    class << self
      def parse_from_json(json, credentials)
        member = Role.new(Conjur::Authz::API.host, credentials)[Conjur::API.parse_role_id(json['member']).join('/')]
        grantor = Role.new(Conjur::Authz::API.host, credentials)[Conjur::API.parse_role_id(json['grantor']).join('/')]
        RoleGrant.new(member, grantor, json['admin_option'])
      end
    end
  end
end