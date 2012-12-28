require 'rest-client'
require 'json'

require 'conjur/api/servers'

module Conjur
  class API
    class << self
      def get_key user, pass
        RestClient::Resource.new(Conjur::API.host, user, pass)['user/api_key'].get
      end
      
      def host
        ENV['CONJUR_URL'] || default_host
      end
      
      def default_host
        "http://localhost:5000"
      end
    end
    
    def initialize user, api_key
      @user = user
      @api_key = api_key
    end
    
    attr_reader :api_key, :user
    
    def host
      self.class.host
    end
    
    def post path, options, &block
      resource[path].post(options)
    end
    
    def credentials
      { user: user, password: api_key }
    end
    
    def resource url = host
      RestClient::Resource.new(url, credentials)
    end
    
    def escape(str)
      require 'uri'
      URI.escape(str, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    end
  end
end
