module Conjur
  class Resource < RestClient::Resource
    include Exists
    
    def kind
      match_path(1)
    end

    def identifier
      match_path(2)
    end
    
    def create
      self.put({}, content_type: :json)
    end

    def delete
      self.delete
    end

    def permit(privilege, role, options = {})
      self["?grant&privilege=#{escape privilege}&role=#{escape role}"].post(options)
    end
    
    def deny(privilege, role, options = {})
      self["?revoke&privilege=#{escape privilege}&role=#{escape role}"].post(options)
    end
    
    protected
    
    def match_path(index)
      require 'uri'
      match = URI.parse(self.url).path.match(/^\/([^\/]+)\/([^\/]+)(?:\/|$)/)
      URI.unescape(match[index])
    end
  end
end