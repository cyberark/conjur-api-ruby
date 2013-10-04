#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
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