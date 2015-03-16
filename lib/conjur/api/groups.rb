# Copyright (C) 2013-2015 Conjur Inc.
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
require 'conjur/group'

module Conjur
  class API
    def groups(options={})
      standard_list Conjur::Core::API.host, :group, options
    end

    def create_group(id, options = {})
      standard_create Conjur::Core::API.host, :group, id, options
    end

    def group id
      standard_show Conjur::Core::API.host, :group, id
    end

    # Find groups by GID.
    #
    # @param [Hash] options search criteria
    # @option options [Integer] :gidnumber GID number
    # @return [Array<String>] group names matching the criteria
    #
    # @note You can get a {Conjur::Group} by calling {Conjur::API#group}, eg.:
    #   +api.find_groups(gidnumber: 12345).map(&api.method(:group))+
    def find_groups options
      JSON.parse(Conjur::REST.new(Conjur::Core::API.host, credentials)\
                 ["groups/search?#{options.to_query}"].get)
    end
  end
end
