require 'possum/authenticator'

module Possum
  # An {Authenticator} which uses an API key to fetch tokens.
  # @note Automatically used internally by {Possum::Client}.
  class ApiKeyAuthenticator < Authenticator
    # Create a new ApiKeyAuthenticator.
    # @param [Faraday::Connection] connection The connection to use to fetch tokens.
    # @param [String] account The account in which to login.
    # @param [String] username The username to authenticate as.
    # @param [String] api_key The API key to use for authentication.
    def initialize connection, account, username, api_key
      @connection = connection.dup
      @connection.url_prefix += "/authn/#{Faraday::Utils.escape account}/#{Faraday::Utils.escape username}/authenticate"
      @api_key = api_key
    end

    # Fetch a new token.
    def fetch_token
      response = @connection.post { |req| req.body = @api_key }
      if response.success?
        [response.body].pack 'm0'
      else
        raise UnexpectedResponseError.new response
      end
    end
  end
end
