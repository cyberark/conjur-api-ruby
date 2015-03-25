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
    # @!group Directory: Groups

    # List all Conjur groups visible to the current role.  This method does not
    # support advanced query options.  If you want those, use `#resources` with
    # the `:kind` option set to `'group'`.
    #
    # @example
    #   api.groups.count # => 163 (yikes!)
    #
    # @param options [Hash] included for compatibility.  Do not use this parameter!
    # @return [Array<Conjur::Group>]
    def groups(options={})
      standard_list Conjur::Core::API.host, :group, options
    end

    # Create a new group with the given identifier.
    #
    # Groups can be created with a gidnumber attribute, which is used when mapping LDAP/ActiveDirectory groups
    # to Conjur groups, and when performing PAM authentication to assign a unix GID.
    #
    #
    # @example
    #   group = api.create_group 'cats'
    #   puts group.attributes
    #   # Output
    #   {"id"=>"cats",
    #     "userid"=>"admin",
    #     "ownerid"=>"conjur:user:admin",
    #     "gidnumber"=>nil,
    #     "roleid"=>"conjur:group:cats",
    #     "resource_identifier"=>"conjur:group:cats"}
    #
    # @example Create a group with a GID number.
    #   group = api.create_group 'dogs', gidnumber: 1337
    #   puts group.attributes['gidnumber']
    #   # Output
    #   1337
    #
    # @param [String] id the identifier for this group
    # @param [Hash] options options for group creation
    # @option options [FixNum] :gidnumber gidnumber to assign to this group (if not present, the
    #   group will *not* have a gidnumber, in contrast to Conjur {Conjur::User} instances).
    # @return [Conjur::Group] the group created.
    def create_group(id, options = {})
      standard_create Conjur::Core::API.host, :group, id, options
    end


    # Fetch a group with the given id.  Note that the id is *unqualified* -- it must not contain
    # `account` or `id` parts.  For example,
    #
    # @example
    #   group = api.create_group 'fish'
    #   right = api.group 'fish'
    #   wrong = api.group 'conjur:group:fish'
    #   right.exists? # => true
    #   wrong.exists? # => false
    #
    # @param [String] id the identifier of the group
    # @return [Conjur::Group] the group, which may or may not exist (you must check this using the {Conjur::Exists#exists?})
    #   method.
    def group id
      standard_show Conjur::Core::API.host, :group, id
    end

    # Find groups by GID.  Note that gidnumbers are *not* unique for groups.
    #
    # @example
    #   dogs = api.create_group 'dogs', gidnumber: 42
    #   cats = api.create_group 'cats', gidnumber: 42
    #   api.find_groups gidnumber: 42
    #   # => ['cats', 'dogs']
    #
    # @example
    #   groups = api.find_groups(gidnumber: 42).map{|id| api.group(id)}
    #   groups.map(&:class) # => [Conjur::Group, Conjur::Group]
    #
    # @param [Hash] options search criteria
    # @option options [Integer] :gidnumber GID number
    # @return [Array<String>] group names matching the criteria
    def find_groups options
      JSON.parse(RestClient::Resource.new(Conjur::Core::API.host, credentials)["groups/search?#{options.to_query}"].get)
    end
    #@!endgroup
  end
end
