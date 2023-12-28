module Conjur
  module Routing
    def url_for method, *args
      router.send method, *args
    end

    def parser_for method, *args
      router.send "parse_#{method}", *args
    end

    protected

    def router
      require 'conjur/api/router'

      Conjur::API::Router
    end
  end
end
