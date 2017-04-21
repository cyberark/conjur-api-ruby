module Conjur

  # A Conjur Layer is a type of role whose members are Conjur Hosts. The hosts inherit
  # permissions from the layer. Automatic roles on the layer can also be used to manage
  # SSH permissions to the hosts.
  #
  # @example Allow hosts in the layer `dev/database` to access a `dev/database_uri` secret
  #   # Create the layer and add a couple of EC2 hosts
  #   layer = api.show 'layer:dev/database'
  #   hosts = ['ec2-iac5ed', 'ec2-iadc31'].map{ |hostid| api.show "host:#{hostid}" }
  #   hosts.each{ |host| layer.add_host host }
  #
  #   # A Variable representing the database uri secret
  #   database_uri  = api.show 'variable:dev/database_uri'
  #
  #   # Currently none of the hosts can access it:
  #   hosts.any?{ |host| host.role.permitted? database_uri, 'execute' } # => false
  #
  #   # Grant permission on the layer
  #
  #   # Now all hosts in the layer have the execute permission on the secret through the layer
  #   hosts.all?{ |host| host.role.permitted? database_uri, 'execute' } # => true
  #
  class Layer < BaseObject
    include ActsAsRolsource
    
    # Lists the roles that have been granted access to the host's owned roles.
    #
    # @param [String] role_name Either `use_host` or `admin_host`
    # @return [Conjur::RoleGrant] the grants associated with this host (the return type
    #   is identical to that of {Conjur::Role#members}).
    def hosts_members(role_name)
      owned_role(role_name).members
    end

    # Return all hosts in the layer.
    #
    # @return [Array<Conjur::Host>] the hosts in the layer.
    def hosts
      attributes['hosts'].map do |id|
        build_object id
      end
    end
  end
end
