require 'rest-client'
require 'json'

require 'conjur/exists'
require 'conjur/has_attributes'

module Conjur
  class API
    def initialize user, api_key
      @user = user
      @api_key = api_key
    end
    
    attr_reader :api_key, :user
    
    def host
      self.class.host
    end
    
    def credentials
      { user: user, password: api_key }
    end
    
    def escape(str)
      require 'uri'
      URI.escape(str, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    end
  end
end
