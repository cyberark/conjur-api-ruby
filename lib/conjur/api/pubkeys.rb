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
    # Return all of a user's public keys, as a newline delimited string
    # (the format expected by authorized-keys)
    def public_keys username
      public_keys_resource(username).get
    end
    
    # Return a specific public key for a given user and key name
    def public_key username, keyname
      public_keys_resource(username, keyname).get
    end
    
    # Add a public key for the given user
    def add_public_key username, key
      public_keys_resource(username).post key
    end
    
    # Delete a public key for the given user and key name
    def delete_public_key username, keyname
      public_keys_resource(username, keyname).delete
    end
    
    protected
    def public_keys_resource *path
      RestClient::Resource.new(Conjur::API.pubkeys_asset_host, credentials)[public_keys_path *path]
    end
    
    def public_keys_path *args
      args.map{|a| fully_escape(a)}.join('/')
    end
  end
end
