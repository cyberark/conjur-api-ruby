module Conjur
  class LdapSyncJob
    attr_reader :id, :type, :state, :exclusive

    alias exclusive? exclusive

    # Creates a new `LdapSyncJob` from a Hash as returned
    # by the LDAP sync service's `GET /jobs` route.
    def self.new_from_json api, hash
      @api = api

      %w(id type state exclusive).each do |k|
        instance_variable_set "@#{k}", hash[k]
      end
    end

    def initialize api, id, type, state, exclusive
      @api = api
      @id = id
      @type = type
      @state = state
      @exclusive = exclusive
    end

    # Stop this job (if running) and remove it from the list of jobs.
    def delete
      job_resource.delete
    end

    # Receive output from this job and pass them to the given block.
    def output &block
      raise "not implemented"
    end

    def == o
      o.kind_of?(self.class) and o.id == self.id
    end

    def to_s
      "<LdapSyncJob #{id} type=#{type} state=#{state}#{exclusive? ? ' exclusive' : ''}>"
    end

    private

    def job_resource
      RestClient::Resource.new(Conjur.configuration.account, @api.credentials)['ldap-sync']['jobs'][id]
    end
  end
end