module Conjur

  # A {http://developer.conjur.net/reference/services/directory/layer Conjur Layer}
  # represents a collection of
  # {http://developer.conjur.net/reference/services/directory/host Conjur Hosts} with the
  # ssame permissions on other Conjur resources.
  #
  # @example Allow hosts in the layer `dev/database` to access a `dev/database_uri` secret
  #   # Create the layer and add a couple of EC2 hosts
  #   layer = api.create_layer 'dev/database'
  #   hosts = ['ec2-iac5ed', 'ec2-iadc31'].map{ |hostid| api.create_host id: hostid }
  #   hosts.each{ |host| layer.add_host host }
  #
  #   # A Variable representing the database uri secret
  #   database_uri  = api.variable 'dev/database_uri'
  #
  #   # Currently none of the hosts can access it:
  #   hosts.any?{ |host| host.role.permitted? database_uri, 'execute' } # => false
  #
  #   # Grant permission on the layer
  #   database_uri.resource.permit 'execute', layer
  #
  #   # Now all hosts in the layer have the execute permission on the secret through the layer
  #   hosts.all?{ |host| host.role.permitted? database_uri, 'execute' } # => true
  #
  class Layer < RestClient::Resource
    include ActsAsAsset
    include ActsAsRole

    # Add a host to this layer.  The host's role will become a member of the layer's role, and have
    # all privileges of the layer.
    #
    # @param [String, Conjur::Host] hostid A *qualified* Conjur id for the host, or a {Conjur::Host} instance.
    # @return [void]
    def add_host(hostid)
      hostid = cast(hostid, :roleid)
      log do |logger|
        logger << "Adding host #{hostid} to layer #{id}"
      end
      invalidate do
        RestClient::Resource.new(self['hosts'].url, options).post(hostid: hostid) 
      end
    end

    # Remove a host from this layer.  The host will lose all privileges it had through this
    # layer.
    #
    # @param [String, Conjur::Host] hostid A *qualified* Conjur id for the host, or a {Conjur::Host} instance.
    # @return [void]
    def remove_host(hostid)
      hostid = cast(hostid, :roleid)
      log do |logger|
        logger << "Removing host #{hostid} from layer #{id}"
      end
      invalidate do
        RestClient::Resource.new(self["hosts/#{fully_escape hostid}"].url, options).delete
      end
    end
    
    # Lists the roles that have been granted access to the host's owned roles.
    #
    # `role_name` can be either `admin_host` or `use_host`.  This method corresponds
    # to {Conjur::ActsAsAsset#add_member} in that members added with that method
    # will be returned by this method.
    #
    # @param [String] role_name Either `use_host` or `admin_host`
    # @return [Conjur::RoleGrant] the grants associated with this host (the return type
    #   is identical to that of {Conjur::Role#members}).
    # @see Conjur::ActsAsAsset#add_member
    def hosts_members(role_name)
      owned_role(role_name).members
    end


    # Return all hosts in the layer.
    #
    # @return [Array<Conjur::Host>] the hosts in the layer.
    def hosts
      self.attributes['hosts'].collect do |id|
        Conjur::Host.new(Conjur::API.core_asset_host, options)["hosts/#{fully_escape id.split(':', 3)[-1]}"]
      end
    end
  end
end
