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
    # Return audit events related to the given role_id.  Identitical to audit_events
    # except that a String may be given instead of a Role object.
    # @param role [String] the role for which events should be returned.
    def audit_role role, options={}
      audit_event_feed 'role', (role.roleid rescue role), options
    end
    
    
    # Return audit events related to the current authenticated role.
    def audit_current_role options={}
      audit_event_feed 'role', nil, options
    end
    
    # Return audit events related to the given resource
    def audit_resource resource, options={}
      audit_event_feed 'resource', (resource.resourceid rescue resource), options
    end
    
    private
    def audit_event_feed kind, identifier=nil, options={}
      path = "feeds/#{kind}"
      path << "/#{CGI.escape identifier}" if identifier
      query = options.slice(:limit, :offset)
      path << "?#{query.to_param}" unless query.empty?
      parse_response RestClient::Resource.new(Conjur::Audit::API.host, credentials)[path].get
    end
    
    def parse_response response
      JSON.parse response
    end
  end
end