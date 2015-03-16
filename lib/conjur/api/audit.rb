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

require 'conjur/event_source'
module Conjur
  class API
    # Return all events visible to the current authorized role
    def audit options={}, &block
      audit_event_feed "", options, &block
    end
    
    # Return audit events related to the given role_id.  Identitical to audit_events
    # except that a String may be given instead of a Role object.
    # @param role [String] the role for which events should be returned.
    def audit_role role, options={}, &block
      audit_event_feed "roles/#{CGI.escape cast(role, :roleid)}", options, &block
    end
    
    # Return audit events related to the given resource
    def audit_resource resource, options={}, &block
      audit_event_feed "resources/#{CGI.escape cast(resource, :resourceid)}", options, &block
    end
    
    private
    def audit_event_feed path, options={}, &block
      query = options.slice(:since, :till)
      path << "?#{query.to_param}" unless query.empty? 
      if options[:follow]
        follow_events path, &block
      else
        parse_response(
          Conjur::REST.new(Conjur::Audit::API.host, credentials)[path].get
        ).tap do |events|
          block.call(events) if block
        end
      end
    end
    
    def follow_events path, &block
      opts = credentials.dup.tap{|h| h[:headers][:accept] = "text/event-stream"}
      block_response = lambda do |response|
        response.error! unless response.code == "200"
        es = EventSource.new
        es.message{ |e| block[e.data] }
        response.read_body do |chunk|
          es.feed chunk
        end
      end
      url = "#{Conjur::Audit::API.host}/#{path}"
      RestClient::Request.execute(
        url: url,
        headers: opts[:headers],
        method: :get,
        block_response: block_response
      )
    end
    
    def parse_response response
      JSON.parse response
    end
  end
end
