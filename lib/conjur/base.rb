#
# Copyright (C) 2013-2014 Conjur Inc
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
require 'rest-client'
require 'json'
require 'base64'

require 'conjur/exists'
require 'conjur/has_attributes'
require 'conjur/has_owner'
require 'conjur/path_based'
require 'conjur/escape'
require 'conjur/log'
require 'conjur/log_source'
require 'conjur/standard_methods'
require 'conjur/cast'

module Conjur
  # NOTE: You have to put all 'class level' api docs here, because YARD is stoopid :-(

  # This class provides access to Conjur services
  # **TODO MOAR**
  #
  # # Conjur Services
  #
  # ### Public Keys Service
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
  #
  #
  # ### Audit Service
  #
  # The {http://developer.conjur.net/reference/services/audit Conjur Audit Service} allows you to
  # fetch audit records.
  #
  # Generally you will need to have *at least one* privilege on the subject of an event in order to see it.
  class API
    include Escape
    include LogSource
    include StandardMethods
    include Cast

    class << self
      # @api private
      # Parse a role id into [ account, 'roles', kind, id ]
      def parse_role_id(id)
        id = id.role if id.respond_to?(:role)
        if id.is_a?(Role)
          [ id.account, 'roles', id.kind, id.identifier ]
        elsif id.respond_to?(:role_kind)
          [ Conjur::Core::API.conjur_account, 'roles', id.role_kind, id.identifier ]
        else
          parse_id id, 'roles'
        end
      end

      # @api private
      # Parse a resource id into [ account, 'resources', kind, id ]
      def parse_resource_id(id)
        id = id.resource if id.respond_to?(:resource)
        if id.is_a?(Resource)
          [ id.account, 'resources', id.kind, id.identifier ]
        elsif id.respond_to?(:resource_kind)
          [ Conjur::Core::API.conjur_account, 'resources', id.resource_kind, id.resource_id ]
        else
          parse_id id, 'resources'
        end
      end
    
      # @api private
      # Converts flat id into path components, with mixed-in "super-kind"
      #                                     (not that kind which is part of id)
      # NOTE: name is a bit confusing, as result of 'parse' is just recombined
      #       representation of parts, not an object of higher abstraction level
      def parse_id(id, kind)
        # Structured IDs (hashes) are no more supported
        raise "Unexpected class #{id.class} for #{id}" unless id.is_a?(String)
        paths = path_escape(id).split(':')
        if paths.size < 2
          raise "Expecting at least two tokens in #{id}"
        elsif paths.size == 2
          paths.unshift Conjur::Core::API.conjur_account
        end
        # I would strongly recommend to encapsulate this into object 
        [ paths[0], kind, paths[1], paths[2..-1].join(':') ]
      end


      # Create a new {Conjur::API} instance from a username and a password or api key.
      #
      # @example Create an API with valid credentials
      #   api = Conjur::API.new_from_key 'admin', '<admin password>'
      #   api.current_role # => 'conjur:user:admin'
      #   api.token['data'] # => 'admin'
      #
      # @example Authentication is lazy
      #   api = Conjur::API.new_from_key 'admin', 'wrongpassword'   # succeeds
      #   api.user 'foo' # raises a 401 error
      #
      # @param [String] username the username to use when making authenticated requests.
      # @param [Sring] api_key the api key or password for `username`
      # @return [Conjur::API] an api that will authenticate with the given username and api key.
      def new_from_key(username, api_key)
        self.new username, api_key, nil
      end


      # Create a new {Conjur::API} instance from a token issued by the
      # {http://developer.conjur.net/reference/services/authentication Conjur authentication service}
      #
      # Generally, you will have a Conjur identitiy (username and api key), and create an {Conjur::API} instance
      # for the identity using {.new_from_key}.  This method is useful when you are performing authorization checks
      # given a token.  For example, a Conjur gateway that requires you to prove that you can 'read' a resource named
      # 'super-secret' might get the token from a request header, create an {Conjur::API} instance with this method,
      # and use {Conjur::Resource#permitted?} to decide whether to accept and forward the request.
      #
      # Note that Conjur tokens are issued as JSON.  This method expects to get the token as a parsed JSON Hash.
      # When sending tokens as headers, you will normally use base64 encoded strings.  Authorization headers
      # used by Conjur have the form `'Token token="#{b64encode token.to_json}"'`, but this format is in no way
      # required.
      #
      # @example A simple gatekeeper
      #   RESOURCE_NAME = 'protected-service'
      #
      #   def handle_request request
      #     token_header = request.header 'X-Conjur-Token'
      #     token = JSON.parse Base64.b64decode(token_header)
      #
      #     api = Conjur::API.new_from_token token
      #     raise Forbidden unless api.resource(RESOURCE_NAME).permitted? 'read'
      #
      #     proxy_to_service request
      #   end
      #
      # @param [Hash] token the authentication token as parsed JSON to use when making authenticated requests
      # @return [Conjur::API] an api that will authenticate with the token
      def new_from_token(token)
        self.new nil, nil, token
      end
    end
    
    # Create a new instance from a username and api key or a token.
    #
    # @note You should use {Conjur::API.new_from_token} or {Conjur::API.new_from_key} instead of calling this method
    #   directly.
    #
    # This method requires that you pass **either** a username and api_key **or** a token Hash.
    #
    # @param [String] username the username to authenticate as
    # @param [String] api_key the api key or password to use when authenticating
    # @param [Hash] token the token to use when making authenticated requuests.
    #
    # @api internal
    def initialize username, api_key, token
      @username = username
      @api_key = api_key
      @token = token

      raise "Expecting ( username and api_key ) or token" unless ( username && api_key ) || token
    end
    
    attr_reader :api_key

    #
    def username
      @username || @token['data']
    end


    def host
      self.class.host
    end

    def token
      @token = nil unless token_valid?

      @token ||= Conjur::API.authenticate(@username, @api_key)

      fail "obtained token is invalid" unless token_valid? # sanity check

      return @token
    end
    
    # Authenticate the username and api_key to obtain a request token.
    # Tokens are cached by username for a short period of time.
    def credentials
      { headers: { authorization: "Token token=\"#{Base64.strict_encode64 token.to_json}\"" }, username: username }
    end

    private

    def token_valid?
      return false unless @token
      
      # Actual token expiration is 8 minutes, but why cut it so close
      expiration = 5.minutes
      Time.now - Time.parse(@token['timestamp']) < expiration
    end
  end
end
