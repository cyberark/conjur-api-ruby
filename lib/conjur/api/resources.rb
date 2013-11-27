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
require 'conjur/resource'

module Conjur
  class API
    def create_resource(identifier, options = {})
      resource(identifier).tap do |r|
        r.create(options)
      end
    end
    
    def resource identifier
      paths = path_escape(identifier).split(':')
      raise ArgumentError, "Expected at least 3 tokens in resource identifier '#{identifier}'" if paths.length < 3
      path = [ paths[0], 'resources', paths[1], paths[2..-1].join(':') ].flatten.join('/')
      Resource.new(Conjur::Authz::API.host, credentials)[path]
    end

    # Return all visible resources.
    # In opts you should pass an account to filter by, and optionally a kind.
    def resources opts = {}
      Resource.all({ host: Conjur::Authz::API.host, credentials: credentials }.merge opts)
        .map { |r| resource r }
    end
  end
end
