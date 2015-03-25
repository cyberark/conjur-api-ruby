module Conjur
  class Layer < Conjur::REST
    include ActsAsAsset
    include ActsAsRole
    
    def add_host(hostid)
      hostid = cast(hostid, :roleid)
      log do |logger|
        logger << "Adding host #{hostid} to layer #{id}"
      end
      invalidate do
        Conjur::REST.new(self['hosts'].url, options).post(hostid: hostid)
      end
    end
    
    def remove_host(hostid)
      hostid = cast(hostid, :roleid)
      log do |logger|
        logger << "Removing host #{hostid} from layer #{id}"
      end
      invalidate do
        Conjur::REST.new(self["hosts/#{fully_escape hostid}"].url, options).delete
      end
    end
    
    # Lists the roles that have been granted access to the hosts owned roles.
    def hosts_members(role_name)
      owned_role(role_name).members
    end

    def hosts
      self.attributes['hosts'].collect do |id|
        Conjur::Host.new(Conjur::API.core_asset_host, options)["hosts/#{fully_escape id}"]
      end
    end
  end
end
