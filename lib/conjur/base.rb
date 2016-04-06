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

  # This class provides access to the Conjur services.
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
      # @param [String] api_key the api key or password for `username`
      # @param [String] remote_ip the optional IP address to be recorded in the audit record.
      # @return [Conjur::API] an api that will authenticate with the given username and api key.
      def new_from_key(username, api_key, remote_ip = nil)
        self.new username, api_key, nil, remote_ip
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
      # @param [String] remote_ip the optional IP address to be recorded in the audit record.
      # @return [Conjur::API] an api that will authenticate with the token
      def new_from_token(token, remote_ip = nil)
        self.new nil, nil, token, remote_ip
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
    # @param [String] remote_ip the optional IP address to be recorded in the audit record.
    #
    # @api internal
    def initialize username, api_key, token, remote_ip = nil
      @username = username
      @api_key = api_key
      @token = token
      @remote_ip = remote_ip

      raise "Expecting ( username and api_key ) or token" unless ( username && api_key ) || token
    end

    #@!attribute [r] api_key
    # The api key used to create this instance.  This is only present when you created the api with {Conjur::API.new_from_key}.#
    #
    # @return [String] the api key, or nil if this instance was created from a token.
    attr_reader :api_key
    
    #@!attribute [r] remote_ip
    # An optional IP address to be recorded in the audit record for any actions performed by this API instance.
    attr_reader :remote_ip

    #@!attribute [rw] privilege
    # The optional global privilege (e.g. 'elevate' or 'reveal') which should be attempted on the request.
    attr_accessor :privilege

    #@!attribute [rw] audit_roles
    # An array of role ids that should be included in any audit
    # records generated by requsts made by this instance of the api.
    attr_accessor :audit_roles

    #@!attribute [rw] audit_resources
    # An array of resource ids that should be included in any audit
    # records generated by requsts made by this instance of the api.
    attr_accessor :audit_resources

    # The name of the user as which this api instance is authenticated.  This is available whether the api
    # instance was created from credentials or an authentication token.
    #
    # @return [String] the login of the current user.
    def username
      @username || @token['data']
    end
    
    # Perform all commands in Conjur::Bootstrap::Command.
    def bootstrap listener
        Conjur::Bootstrap::Command.constants.map{|c| Conjur::Bootstrap::Command.const_get(c)}.each do |cls|
        next unless cls.is_a?(Class)
        next unless cls.superclass == Conjur::Bootstrap::Command::Base
        cls.new(self, listener).perform
      end
    end

    # @api private
    # used to delegate to host providing subclasses.
    # @return [String] the host
    def host
      self.class.host
    end

    # The token used to authenticate requests made with the api.  The token will be fetched
    # if it hasn't already, or if it has expired.  Accordingly, this method may raise a RestClient::Unauthorized
    # exception if the credentials are invalid.
    #
    # @note calling this method on an {Conjur::API} instance created with {Conjur::API.new_from_token} will have
    # undefined behavior if the token is expired.
    #
    # @return [Hash] the authentication token as a Hash
    # @raise [RestClient::Unauthorized] if the username and api key are invalid.
    def token
      @token = nil unless token_valid?

      @token ||= Conjur::API.authenticate(@username, @api_key)

      validate_token

      return @token
    end

    # Credentials that can be merged with options to be passed to `RestClient::Resource` HTTP request methods.
    # These include a username and an Authorization header containing the authentication token.
    #
    # @return [Hash] the options.
    # @raise [RestClient::Unauthorized] if fetching the token fails.
    # @see {#token}
    def credentials
      headers = {}.tap do |h|
        h[:authorization] = "Token token=\"#{Base64.strict_encode64 token.to_json}\""
        h[:x_conjur_privilege] = @privilege if @privilege
        h[:x_forwarded_for] = @remote_ip if @remote_ip
        h[:conjur_audit_roles] = Base64.strict_encode64(@audit_roles.join("\n")) if @audit_roles
        h[:conjur_audit_resources] = Base64.strict_encode64(@audit_resources.join("\n")) if @audit_resources
      end
      { headers: headers, username: username }
    end

    # Return a new API object with the specified X-Conjur-Privilege.
    # 
    # @return The API instance.
    def with_privilege privilege
      self.class.new(username, api_key, token, remote_ip).tap do |api|
        api.privilege = privilege
      end
    end

    def with_audit_roles role_ids
      role_ids = Array(role_ids)
      self.class.new(username, api_key, token, remote_ip).tap do |api|
        # Ensure that all role ids are fully qualified
        api.audit_roles = role_ids.collect { |id| api.role(id).roleid }
      end
    end

    def with_audit_resources resource_ids
      resource_ids = Array(resource_ids)
      self.class.new(username, api_key, token, remote_ip).tap do |api|
        # Ensure that all resource ids are fully qualified
        api.audit_resources = resource_ids.collect { |id| api.resource(id).resourceid }
      end
    end

    private

    def token_valid?
      begin
        validate_token
        return true
      rescue Exception
        return false
      end
    end

    # Check to see if @token is defined, and whether it's expired
    #
    # @raise [Exception] if the token is invalid
    def validate_token
      fail "token not present" unless @token
      
      # Actual token expiration is 8 minutes, but why cut it so close
      expiration = 5.minutes
      lag = Time.now - Time.parse(@token['timestamp'])
      unless lag < expiration
        fail "obtained token is invalid: "\
            "token timestamp is #{@token['timestamp']}, #{lag} seconds ago"
      end
    end
  end
end
