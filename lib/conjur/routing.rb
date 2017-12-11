module Conjur
  module Routing
    def route_to method, *args
      router.send method, *args
    end

    protected

    def router
      require 'conjur/api/router/v4'
      require 'conjur/api/router/v5'

      variable_id = "@v#{Conjur.configuration.major_version}_router"
      router = instance_variable_get variable_id
      if router.nil?
        router = instance_variable_set variable_id, router_for_version
      end
      router
    end

    def router_for_version
      Conjur::API::Router.const_get("V#{Conjur.configuration.major_version}")
    end
  end
end
