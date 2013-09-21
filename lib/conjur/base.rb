require 'rest-client'
require 'json'
require 'base64'

require 'conjur/exists'
require 'conjur/has_attributes'
require 'conjur/has_owner'
require 'conjur/path_based'
require 'conjur/escape'
require 'conjur/log'
require 'conjur/log_source'
require 'conjur/standard_methods'

module Conjur
  class API
    include Escape
    include LogSource
    include StandardMethods
    
    class << self
      # Parse a role id into [ account, 'roles', kind, id ]
      def parse_role_id(id)
        parse_id id, 'roles'
      end

      # Parse a resource id into [ account, 'resources', kind, id ]
      def parse_resource_id(id)
        parse_id id, 'resources'
      end
      
      def parse_id(id, kind)
        if id.is_a?(Hash)
          tokens = id['id'].split(':')
          [ id['account'], kind, tokens[0], tokens[1..-1].join(':') ]
        elsif id.is_a?(String)
          paths = path_escape(id).split(':')
          if paths.size < 2
            raise "Expecting at least two tokens in #{id}"
          elsif paths.size == 2
            paths.unshift Conjur::Core::API.conjur_account
          end
          [ paths[0], kind, paths[1], paths[2..-1].join(':') ]
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
      @token ||= Conjur::API.authenticate(@username, @api_key)
    end
    
    # Authenticate the username and api_key to obtain a request token.
    # Tokens are cached by username for a short period of time.
    def credentials
      { headers: { authorization: "Token token=\"#{Base64.strict_encode64 token.to_json}\"" }, username: username }
    end
  end
end
