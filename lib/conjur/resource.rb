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
      log do |logger|
        logger << "Creating resource "
        logger << kind
        logger << ":"
        logger << identifier
      end
      self.put({}, content_type: :json)
    end

    def delete
      log do |logger|
        logger << "Creating resource "
        logger << kind
        logger << ":"
        logger << identifier
      end
      self.delete
    end

    def permit(privilege, role, options = {})
      log do |logger|
        logger << "Permitting "
        logger << privilege
        logger << " on resource "
        logger << kind
        logger << ":"
        logger << identifier
        logger << " by "
        logger << role
        if options[:grantor]
          logger << " with grantor "
          logger << options[:grantor]
        end
        if options[:grant_option]
          logger << " with grant option"
        end
      end
      self["?grant&privilege=#{query_escape privilege}&role=#{query_escape role}"].post(options)
    end
    
    def deny(privilege, role, options = {})
      log do |logger|
        logger << "Denying "
        logger << privilege
        logger << "on resource "
        logger << kind
        logger << ":"
        logger << identifier
        logger << " by "
        logger << role
      end
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