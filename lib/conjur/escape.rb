module Conjur
  module Escape
    module ClassMethods
      def escape(str)
        require 'uri'
        URI.escape(str.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end
    end
    
    def self.included(base)
      base.extend ClassMethods
    end

    def escape(str)
      self.class.escape str
    end
  end
end