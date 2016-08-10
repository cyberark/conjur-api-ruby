require 'conjur/event_source'

module Conjur
  class LdapSyncJob
    attr_reader :id, :type, :state, :exclusive

    alias exclusive? exclusive

    # Creates a new `LdapSyncJob` from a Hash as returned
    # by the LDAP sync service's `GET /jobs` route.
    def self.new_from_json api, hash
      new(api, hash['id'], hash['type'], hash['state'], hash['exclusive'])
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
      events = []
      wrapper = lambda do |e|
        events << e
        block[e] if block
      end

      follow_job_output(&wrapper)

      events
    end

    def to_s
      "<LdapSyncJob #{id} type=#{type} state=#{state}#{exclusive? ? ' exclusive' : ''}>"
    end

    def to_h
      {id: id, type: type, state: state, exclusive: exclusive}
    end

    alias as_json to_h

    def to_json _unused
      as_json.to_json
    end
    private

    def follow_job_output &block
      options = @api.credentials.dup.tap{|h| h[:headers][:accept] = 'text/event-stream'}

      handle_response = lambda do |response|
        response.error! unless response.code == '200'
        es = EventSource.new
        es.message{ |e| block[e.data] }

        response.read_body do |chunk|
          es.feed chunk
        end
      end

      RestClient::Request.execute(
          url: "#{job_resource['output'].url}",
          headers: options[:headers],
          method: :get,
          block_response: handle_response
      )
    end

    def job_resource
      RestClient::Resource.new(Conjur.configuration.appliance_url, @api.credentials)['ldap-sync']['jobs'][id]
    end
  end
end