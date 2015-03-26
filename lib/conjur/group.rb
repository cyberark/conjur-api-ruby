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
module Conjur

  # A Conjur {http://developer.conjur.net/reference/services/directory/group Group} represents a collection of
  #   Conjur {http://developer.conjur.net/reference/services/directory/user Users}.
  #   This class represents Conjur group assets and operations on them.
  #
  # You should not create instances of this class directly.  Instead, you can get them from
  # API methods like {Conjur::API#group} and {Conjur::API#groups}.
  #
  class Group < RestClient::Resource
    include ActsAsAsset
    include ActsAsRole

    # Add a user to the group or change whether an existing member can manage other members.
    #
    # @example
    #   # create an empty group
    #   group = api.create_group 'hoommans'
    #   # put a user in the group, with the ability to manage members
    #   group.add_member 'conjur:user:bob', admin_option: True
    #   # Hmm, bob is getting a little suspicious, better lower his privileges.
    #   group.add_member 'conjur:user:bob', admin_option: False
    #
    #   # Notice that this method is idempotent:
    #   group.add_member 'alice'
    #   group.add_member 'alice' # Does nothing, alice is already a member
    #
    #
    # @param [String, Conjur::User, Conjur::Role] member the member to add.  If a String is given, it must
    #   be a *fully qualified* Conjur id.
    # @param [Hash] options
    # @option options [Boolean] :admin_option (False) determines whether the member is able to manage members
    #   of this group.
    # @return [void]
    def add_member(member, options = {})
      role.grant_to member, options
    end

    # Remove a member from this group.
    #
    # ### Notes
    # *  Unlike {#add_member}, this method is *not* idempotent.
    #   This means that calling it twice with the same user will raise a `RestClient::ResourceNotFound`
    #   exception.
    # * The member may be represented as a *qualified* conjur id or a {Conjur::User} instance.  Although
    #   it will accept anything that responds to `#roleid`, the behavior when adding or removing a non-user
    #   role is **undefined**.
    #
    # @example
    #   group = api.group 'admins'
    #   group.add_member 'bob'
    #   group.remove_member 'bob' # OK, bob is a member
    #   group.remove_member 'bob' # raises RestClient::ResourceNotFound
    #
    # @param [String, Conjur::User,Conjur::Role] member
    # @return [void]
    # @raise [RestClient::ResourceNotFound] when you try to remove a user who is not a member of the group.
    def remove_member(member)
      role.revoke_from member
    end

    # Update group properties.  Currently the only supported property is `:gidnumber`.
    #
    # @param [Hash] props new property values
    # @option props [Integer] :gidnumber new GID number
    # @return [void]
    def update props
      # not an alias because doc
      put props
    end
  end
end
