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

require 'active_support/dependencies/autoload'
require 'active_support/core_ext'

module Conjur
  module ActsAsResource
    def resource
      require 'conjur/resource'
      # NOTE: should we use specific class to build sub-url below?
      Conjur::Resource.new(Conjur::Authz::API.host, self.options)[[ core_conjur_account, 'resources', path_escape(resource_kind), path_escape(resource_id) ].join('/')]
    end
    
    def resourceid
      [ core_conjur_account, resource_kind, resource_id ].join(':')
    end
    
    def resource_kind
      self.class.name.split("::")[-1].underscore.split('/').join('-')
    end

    def resource_id
      id
    end

    def delete
      resource.delete
      super
    end
    
    def permit(privilege, role, options = {})
      resource.permit privilege, role, options
    end
    
    def deny(privilege, role)
      resource.deny privilege, role
    end
  end
end
