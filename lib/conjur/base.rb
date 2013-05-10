require 'rest-client'
require 'json'

require 'conjur/exists'
require 'conjur/has_attributes'
require 'conjur/has_owner'
require 'conjur/path_based'
require 'conjur/escape'
require 'conjur/log'
require 'conjur/log_source'
require 'conjur/standard_methods'
require 'conjur/token_cache'

module Conjur
  class API
    include Escape
    include LogSource
    include StandardMethods
    
    class << self
      # Parse a role id into [ account, 'roles', kind, id ]
      def parse_role_id(id)
        if id.is_a?(Hash)
          tokens = id['id'].split(':')
          [ id['account'], 'roles', tokens[0], tokens[1..-1].join(':') ]
        elsif id.is_a?(String)
          paths = path_escape(id).split(':')
          if paths.size == 2
            paths.unshift Conjur.account
          end
          [ paths[0], 'roles', paths[1], paths[2..-1].join(':') ]
        else
          raise "Unexpected class #{id.class} for #{id}"
        end
      end

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
      TokenCache.store(@token) if token

      raise "Expecting ( username and api_key ) or token" unless ( username && api_key ) || token
    end
    
    attr_reader :api_key, :username
    
    def username
      @username || @token['data']
    end
    
    def host
      self.class.host
    end
    
    def token
      TokenCache.fetch(username, api_key)
    end
    
    # Authenticate the username and api_key to obtain a request token.
    # Tokens are cached by username for a short period of time.
    def credentials
      { headers: { authorization: "Token token=\"#{Base64.strict_encode64 token.to_json}\"" }, username: username }
    end
  end
end
