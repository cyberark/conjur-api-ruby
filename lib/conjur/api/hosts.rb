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

module Conjur
  class API
    class << self
      def enroll_host(url)
        if Conjur.log
          Conjur.log << "Enrolling host with URL #{url}\n"
        end
        require 'uri'
        url = URI.parse(url) if url.is_a?(String)
        response = Net::HTTP.get_response url
        raise "Host enrollment failed with status #{response.code} : #{response.body}" unless response.code.to_i == 200
        mime_type = response['Content-Type']
        body = response.body
        [ mime_type, body ]
      end
    end
    
    def create_host options = {}
      standard_create Conjur::Core::API.host, :host, nil, options
    end
    
    def host id
      standard_show Conjur::Core::API.host, :host, id
    end
  end
end