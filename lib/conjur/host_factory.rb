#
# Copyright (C) 2014 Conjur Inc
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
require 'conjur/host_factory_token'

module Conjur
  class HostFactory < BaseObject
    include ActsAsRolsource
    
    def create_token expiration, options = {}
      options[:expiration] = expiration
      options[:host_factory] = id
      response = JSON.parse core_resource['host_factory_tokens'].post(options)
      response.map do |data|
        HostFactoryToken.new data, credentials
      end
    end

    def tokens
      # Tokens list is not returned by +show+ if the caller doesn't have permission
      return nil unless self.attributes['tokens']

      self.attributes['tokens'].collect do |data|
        HostFactoryToken.new data, credentials
      end
    end
  end
end
