module Conjur
  class Resource < RestClient::Resource
    include Exists
    
    def kind
      match_path(0..0)
    end

    def identifier
      match_path(1..-1)
    end
    
    def create(options = {})
      log do |logger|
        logger << "Creating resource "
        logger << kind
        logger << ":"
        logger << identifier
        unless options.empty?
          logger << " with options "
          logger << options.to_json
        end
      end
      self.put({}, content_type: :json)
    end

    def delete
      log do |logger|
        logger << "Creating resource #{kind} : #{identifier}"
      end
      self.delete
    end

    def permit(privilege, role, options = {})
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Permitting #{p} on resource #{kind} : #{identifier} by #{role}"
          logger << " with grantor #{options[:grantor]}" if options[:grantor]
          logger << " with grant option" if options[:grant_option]
        end
        self["?grant&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
      end
    end
    
    def deny(privilege, role, options = {})
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Denying #{p} on resource #{kind} : #{identifier} by #{role}"
        end
        self["?revoke&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
      end
    end
    
    protected
    
    def eachable(item)
      item.respond_to?(:each) ? item : [ item ]
    end
    
    def match_path(range)
      require 'uri'
      tokens = URI.parse(self.url).path[1..-1].split('/')[range]
      tokens.map{|t| URI.unescape(t)}.join('/')
    end
  end
end