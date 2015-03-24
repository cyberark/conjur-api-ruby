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
  # # Public Keys Service
  # The {http://developer.conjur.net/reference/services/pubkeys Conjur Public Keys} service provides a
  # simple database of public keys with access controlled by Conjur.  Reading a user's public keys requires
  # no authentication at all -- the user's public keys are public information, after all.
  #
  # Adding or deleting a public key may only be done if you have permission to update the *public keys
  # resource*, which is created when the appliance is launched, and has a resource id
  # `'<organizational account>:service:pubkeys-1.0/public-keys'`.  The appliance also comes with a Group named
  # `'pubkeys-1.0/key-managers'` that has this permission.  Rather than granting each user permission to
  # modify the public keys database, you should consider adding users to this group.
  #
  # A very common use case is {http://developer.conjur.net/tutorials/ssh public key management for SSH}
   class API
    # @!group Public Keys Service

    # Fetch *all*  public keys for the user.  This method returns a newline delimited
    # String for compatibility with the authorized_keys SSH format.
    #
    #
    # If the given user does not exist, an empty String will be returned.  This is to prevent attackers from determining whether
    # a user exists.
    #
    # ## Permissions
    # You do not need any special permissions to call this method, since public keys are, well, public.
    #
    #
    # @example
    #   puts api.public_keys('jon')
    #   # ssh-rsa [big long string] jon@albert
    #   # ssh-rsa [big long string] jon@conjurops
    #
    # @param [String] username the *unqualified* Conjur username
    # @return [String] newline delimited public keys
    def public_keys username
      public_keys_resource(username).get
    end

    
    # Fetch a specific key by name.  The key name is the last token in the public key itself,
    # typically formatted as `'<login>@<hostname>'`.
    #
    # ## Permissions
    # You do not need any special permissions to call this method, since public keys are, well, public.
    #
    # @example Get bob's key for  'bob@somehost'
    #   key = begin
    #     api.public_key 'bob', 'bob@somehost'
    #   rescue RestClient::ResourceNotFound
    #     puts "Key or user not found!"
    #     # Deal with it
    #   end
    #
    #
    # @param [String] username A Conjur username
    # @param [String] keyname The name or identifier of the key
    # @return [String] the public key
    # @raise [RestClient::ResourceNotFound] if the user or key does not exist.
    def public_key username, keyname
      public_keys_resource(username, keyname).get
    end

    # List the public key names for the given user.
    #
    # If the given user does not exist, an empty Array will be returned.  This is to prevent attackers from determining whether
    # a user exists.
    #
    # ## Permissions
    # You do not need any special permissions to call this method, since public keys are, well, public.
    #
    #
    # @example List the names of public keys for 'otto'
    #   api.public_key_names('otto').each{|n| puts n}
    #   # otto@somehost
    #   # admin@someotherhost
    #
    # @example A non existent user has no public keys
    #   user = api.user('doesnotexist')
    #   user.exists? # => false
    #   user.public_key_names # => []
    #
    # @param [String] username the Conjur username
    # @return [Array<String>] the names of the user's public keys
     def public_key_names username
      public_keys(username).lines.map{|s| s.split(' ')[-1]}
    end

    # Add an SSH public key for `username`.
    #
    # ## Key Format
    #
    # This method will raise an exception if `key` is not of the format
    # `"<algorithm> <data> <name>"` (that is, key.split(\s+\)).length must be 3).  The `<name>` field is used by the service
    # to identify individual keys for a user.
    #
    # ## Permissions
    #
    # You must have permission to `'update'` the pubkeys service resource.  When the Conjur appliance
    # is configured, it creates the pubkeys service resource with this identifier
    # `'<organizational account>:service:pubkeys-1.0/public-keys'`.
    #
    # Rather than granting permissions to this resource directly to user roles, we recommend that you add them to the
    # 'key-managers' group, whose *unqualified identifier* is 'pubkeys-1.0/key-managers', which has permission to add public
    # keys.
    #
    # ## Hiding Existence
    #
    # Because attackers could use this method to determine the existence of Conjur users, it will not
    # raise an error if the user does not exist.
    #
    # @example add a user's public key
    #   # Check that the user exists so that we can fail when he doesn't.  Otherwise, this method
    #   # will silently fail.
    #   raise "No such user!" unless api.user('bob').exists?
    #
    #   # Add a key from a file
    #   key = File.read('/path/to/public/key.pub')
    #   api.add_public_key('bob', key)
    #
    # @param [String] username the name of the Conjur
    # @param [String] key an SSH formated public key
    # @return void
    # @raise RestClient::BadRequest when the key is not in the correct format.
    def add_public_key username, key
      public_keys_resource(username).post key
    end

    # Delete a specific public key for a user.
    #
    # ## Permissions
    # You must have permission to `'update'` the pubkeys service resource.  When the Conjur appliance
    # is configured, it creates the pubkeys service resource with this identifier
    # `'<organizational account>:service:pubkeys-1.0/public-keys'`.
    #
    # Rather than granting permissions to this resource directly to user roles, we recommend that you add them to the
    # 'key-managers' group, whose *unqualified identifier* is 'pubkeys-1.0/key-managers', which has permission to add public
    # keys.
    #
    # ## Hiding Existence
    #
    # Because attackers could use this method to determine the existence of Conjur users, it will not
    # raise an error if the user does not exist.
    #
    # @example Delete all public keys for 'bob'
    #
    #   api.public_key_names('bob').count # => 6
    #   api.public_key_names('bob').each do |keyname|
    #     api.delete_public_key 'bob', keyname
    #   end
    #   api.public_key_names('bob').count # => 0
    #
    #
    # @param [String] username the Conjur username/login
    # @param [String] keyname the individual key to delete.
    # @return [void]
    def delete_public_key username, keyname
      public_keys_resource(username, keyname).delete
    end

    #@!endgroup
    
    protected
    # @api private
    # Returns a RestClient::Resource with the pubkeys host and the given path.
    def public_keys_resource *path
      RestClient::Resource.new(Conjur::API.pubkeys_asset_host, credentials)[public_keys_path *path]
    end

    # @api private
    # This method simply escapes each segment in `args` and joins them around `/`.
    def public_keys_path *args
      args.map{|a| fully_escape(a)}.join('/')
    end
  end
end
