require 'rest-client'
require 'json'

require 'conjur/exists'
require 'conjur/has_attributes'
require 'conjur/escape'

module Conjur
  class API
    include Escape
    
    class << self
      def new_from_key(user, api_key)
        self.new user, api_key, nil
      end

      def new_from_token(token)
        self.new nil, nil, token
      end
    end
    
    def initialize user, api_key, token
      @user = user
      @api_key = api_key
      @token = token
      raise "Expecting ( user and api_key ) or token" unless ( user && api_key ) || token
    end
    
    attr_reader :api_key, :user, :token
    
    def host
      self.class.host
    end
    
    def credentials
      if token
        { headers: { authorization: "Conjur #{token.to_s.encode64}" } }
      else
        { user: user, password: api_key }
      end
    end
  end
end
