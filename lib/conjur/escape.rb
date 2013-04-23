module Conjur
  module Escape
    module ClassMethods
      def fully_escape(str)
        require 'cgi'
        CGI.escape(str.to_s)
      end
      
      def path_escape(str)
        path_or_query_escape str
      end

      def query_escape(str)
        path_or_query_escape str
      end
      
      def path_or_query_escape(str)
        return "false" unless str
        str = str.id if str.respond_to?(:id)
        # Leave colons and forward slashes alone
        require 'uri'
        pattern = URI::PATTERN::UNRESERVED + ":\\/@"
        URI.escape(str.to_s, Regexp.new("[^#{pattern}]"))
      end
    end
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    def fully_escape(str)
      self.class.fully_escape str
    end

    def path_escape(str)
      self.class.path_escape str
    end

    def query_escape(str)
      self.class.query_escape str
    end
  end
end