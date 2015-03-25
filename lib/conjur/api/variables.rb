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
require 'conjur/variable'

module Conjur
  class API
    def create_variable(mime_type, kind, options = {})
      standard_create Conjur::Core::API.host, :variable, nil, options.merge(mime_type: mime_type, kind: kind)
    end
    
    def variable id
      standard_show Conjur::Core::API.host, :variable, id
    end

    def variable_values(varlist)
      raise ArgumentError, "Variables list must be an array" unless varlist.kind_of? Array 
      raise ArgumentError, "Variables list is empty" if varlist.empty?
      opts = "?vars=#{varlist.map { |v| fully_escape(v) }.join(',')}"
      begin 
        resp = Conjur::REST.new(Conjur::Core::API.host, credentials)\
            ['variables/values' + opts].get
        return JSON.parse( resp.body ) 
      rescue RestClient::ResourceNotFound 
        return Hash[ *varlist.map { |v| [ v, variable(v).value ]  }.flatten ]  
      end
    end

  end
end
