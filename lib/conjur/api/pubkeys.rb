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

    #@!endgroup
    
    protected
    # @api private
    # Returns a RestClient::Resource with the pubkeys host and the given path.
    def public_keys_resource *path
      RestClient::Resource.new(Conjur.configuration.core_url, credentials)[public_keys_path *path]
    end

    # @api private
    # This method simply escapes each segment in `args` and joins them around `/`.
    def public_keys_path *args
      args.map{|a| fully_escape(a)}.join('/')
    end
  end
end
