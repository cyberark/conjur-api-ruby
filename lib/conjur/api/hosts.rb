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
#
require 'conjur/host'

module Conjur

  class API
    class << self
      # @api private
      # TODO WTF does this do!
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

    #@!group Directory: Hosts

    # Create a new `host` asset.
    #
    # By default this method will create a host with a random id.  However, you may create a host with a
    # specific name by passing an `:id` option.
    #
    # ### Permissions
    #
    # * Any Conjur role may perform this method without an `:ownerid` option.  The new hosts owner will be the current role.
    # * If you pass an ``:ownerid` option, you must be a member of the given role.
    #
    # @example
    #   # Create a host with a random id
    #   anon = api.create_host
    #   anon.id # => "wyzg17"
    #
    #   # Create a host with a given id
    #   foo = api.create_host id: 'foo'
    #   foo.id # => "foo"
    #
    #   # Trying to create a new host named foo fails
    #   foo2 = api.create_host id: 'foo' # raises RestClient::Conflict
    #
    #   # Create a host owned by user 'alice' (assuming we're authenticated as
    #   # a role of which alice is a member).
    #   alice_host = api.create_host id: "host-for-alice", ownerid: 'conjur:user:ailce'
    #   alice_host.ownerid # => "conjur:user:alice"
    #
    # @param [Hash,nil] options options for the new host
    # @option options [String] :id the id for the new host
    # @option options [String] :ownerid set the new hosts owner to this role
    # @return [Conjur::Host] the created host
    # @raise RestClient::Conflict when id is given and a host with that id already exists.
    # @raise RestClient::Forbidden when ownerid is given and the owner role does not exist, or you are not
    #   a member of the owner role.
    #
    def create_host options = nil
      options = options.merge \
          cidr: [*options[:cidr]].map(&CIDR.method(:validate)).map(&:to_s) if options[:cidr]
      standard_create Conjur::Core::API.host, :host, nil, options
    end

    # Get a host by its *unqualified id*.
    #
    # Like other Conjur methods, this will return a {Conjur::Host} whether
    # or not the record is found, and you must use the {Conjur::Exists#exists?} method
    # to check this.
    #
    # @example
    #   api.create_host id: 'foo'
    #   foo = api.host "foo" # => returns a Conjur::Host
    #   puts foo.resourceid # => "conjur:host:foo"
    #   puts foo.id # => "foo"
    #   mistake = api.host "doesnotexist" # => Also returns a Conjur::Host
    #   foo.exists? # => true
    #   mistake.exists? # => false
    #
    # @param [String] id the unqualified id of the host
    # @return [Conjur::Host] an object representing the host, which may or may not exist.
    def host id
      standard_show Conjur::Core::API.host, :host, id
    end

    #@!endgroup
  end
end
