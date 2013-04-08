require 'conjur/group'

module Conjur
  class API
    def groups
      JSON.parse(RestClient::Resource.new(Conjur::Core::API.host, credentials)['groups'].get).collect do |json|
        # TODO: remove this hack
        json = JSON.parse json['json']
        group(json['id'])
      end
    end

    def create_group(id, options = {})
      standard_create Conjur::Core::API.host, :group, id, options
    end

    def group id
      standard_show Conjur::Core::API.host, :group, id
    end
  end
end