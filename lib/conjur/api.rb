require 'rest-client'

module Conjur
  module API
    class << self
      def get_key user, pass
        RestClient::Resource.new(host, user, pass)['user/api_key'].get
      end
      
      def host
        ENV['CONJUR_URL'] || default_host
      end
      
      def default_host
        "http://localhost:3000"
      end
    end
  end
end
