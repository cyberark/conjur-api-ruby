#
# Copyright (C) 2013-2015 Conjur Inc
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
  class API
    class << self
      def core_asset_host
        ::Conjur::Core::API.host
      end
    end
  end
  
  module Core
    class API < Conjur::API
      class << self
        def host
          Conjur.configuration.core_url
        end
        
        def conjur_account
          info['account'] or raise "No account field in #{info.inspect}"
        end
        
        def info
          @info ||= JSON.parse Conjur::REST.new(Conjur::Core::API.host)['info'].get
        end
      end
    end
  end
end

require 'conjur/api/deputies'
require 'conjur/api/hosts'
require 'conjur/api/secrets'
require 'conjur/api/users'
require 'conjur/api/groups'
require 'conjur/api/variables'
