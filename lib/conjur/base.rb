require 'rest-client'
require 'json'

require 'conjur/exists'
require 'conjur/has_attributes'
require 'conjur/escape'
require 'conjur/log'
require 'conjur/log_source'

module Conjur
  class API
    include Escape
    include LogSource
    
    class << self
      def new_from_key(username, api_key)
        self.new username, api_key, nil
      end

      def new_from_token(token)
        self.new nil, nil, token
      end
    end
    
    def initialize username, api_key, token
      @username = username
      @api_key = api_key
      @token = token
      raise "Expecting ( username and api_key ) or token" unless ( username && api_key ) || token
    end
    
    attr_reader :api_key, :username, :token
    
    def username
      @username || token['data']
    end
    
    def host
      self.class.host
    end
    
    def credentials
      if token
        { headers: { authorization: "Token token=\"#{Base64.strict_encode64 token.to_json}\"" }, username: username }
      else
        { user: username, password: api_key }
      end
    end
  end
end
