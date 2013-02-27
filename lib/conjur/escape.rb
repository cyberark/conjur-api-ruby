module Conjur
  module Escape
    module ClassMethods
      def path_escape(str)
        return "false" unless str
        str = str.id if str.respond_to?(:id)
        require 'uri'
        URI.escape(str.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end

      def query_escape(str)
        return "false" unless str
        str = str.id if str.respond_to?(:id)
        require 'uri'
        URI.escape(str.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end
    end
    
    def self.included(base)
      base.extend ClassMethods
    end

    def path_escape(str)
      self.class.path_escape str
    end

    def query_escape(str)
      self.class.query_escape str
    end
  end
end