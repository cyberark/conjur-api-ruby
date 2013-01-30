module Conjur
  class Resource < RestClient::Resource
    include Exists
    
    def kind
      match_path(0..0)
    end

    def identifier
      match_path(1..-1)
    end
    
    def create
      self.put({}, content_type: :json)
    end

    def delete
      self.delete
    end

    def permit(privilege, role, options = {})
      self["?grant&privilege=#{query_escape privilege}&role=#{query_escape role}"].post(options)
    end
    
    def deny(privilege, role, options = {})
      self["?revoke&privilege=#{query_escape privilege}&role=#{query_escape role}"].post(options)
    end
    
    protected
    
    def match_path(range)
      require 'uri'
      tokens = URI.parse(self.url).path[1..-1].split('/')[range]
      tokens.map{|t| URI.unescape(t)}.join('/')
    end
  end
end