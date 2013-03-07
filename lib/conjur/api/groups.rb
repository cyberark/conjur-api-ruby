require 'conjur/group'

module Conjur
  class API
    def create_group(id, options = {})
      log do |logger|
        logger << "Creating group "
        logger << id
      end
      resp = RestClient::Resource.new(Conjur::Core::API.host, credentials)['/groups'].post(options.merge(id: id))
      Group.new(resp.headers[:location], credentials)
    end

    def group id
      Group.new(Conjur::Core::API.host)["/groups/#{path_escape id}"]
    end
  end
end