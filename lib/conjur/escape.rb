module Conjur
  module Escape
    module ClassMethods
      def path_escape(str)
        require 'uri'
        URI.escape(str.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end

      def query_escape(str)
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
  end
end