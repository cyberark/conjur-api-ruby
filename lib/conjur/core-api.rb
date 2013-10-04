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
        def conjur_account
          info['account'] or raise "No account field in #{info.inspect}"
        end
        
        def info
          @info ||= JSON.parse RestClient::Resource.new(Conjur::Core::API.host)['info'].get
        end
        
        def host
          ENV['CONJUR_CORE_URL'] || default_host
        end
        
        def default_host
          case Conjur.env
          when 'test', 'development'
            "http://localhost:#{Conjur.service_base_port + 200}"
          else
            "https://core-#{Conjur.account}-conjur.herokuapp.com"
          end
        end
      end
    end
  end
end

require 'conjur/api/hosts'
require 'conjur/api/secrets'
require 'conjur/api/users'
require 'conjur/api/groups'
require 'conjur/api/variables'