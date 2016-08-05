require 'faraday'
require 'faraday_middleware'

module Possum
  # Possum client object.
  class Client
    # Create a new instance of Possum client.
    #
    # @param [Hash] options The connection options.
    # @option options [String] :url Base URL of the Possum service.
    def initialize options = {}
      @options = options
    end

    # @return [String, nil] account name for the Possum service
    attr_reader :account

    # @return [String, nil] API key for the Possum service
    # @see login
    attr_reader :api_key

    # Set API key to use for this client.
    # @see #login
    def api_key= api_key
      @api_key = api_key
      self.authenticator = ApiKeyAuthenticator.new client, @account, @username, api_key
    end

    # @return [Possum::Authenticator, nil] authenticator in use by this Client
    attr_reader :authenticator

    def authenticator= authenticator
      @client = Faraday.new @options do |client|
        client.request :possum_authenticator, authenticator
        client.response :json, content_type: /\bjson\b/
        client.adapter Faraday.default_adapter
      end
    end

    # Log in to the Possum service by using a password to get an API key.
    # The API key is stored in this client instance and will be used on
    # any further requests.
    #
    # @param [String] account  the account
    # @param [String] username the user name
    # @param [String] password the password
    # @return [String] API key
    # @raise [CredentialError] username or password is incorrect
    # @raise [UnexpectedResponseError] the server has returned an unexpected response
    def login account, username, password
      @account  = account
      @username = username
      res = client.get "/authn/#{account}/login" do |req|
        req.headers['Authorization'] =
            Faraday::Request::BasicAuthentication.header username, password
      end
      parse_login_response res
    end

    # Call Possum using HTTP GET.
    # @note This is a convenience method. If you anticipate non-OK
    #   responses you're encouraged to use {#client} directly.
    #
    # @param [String] path Path to the resource.
    # @param [Hash] params Query parameters.
    # @return [Object, String] Raw or parsed JSON response
    #   (depending on content type).
    # @raise [UnexpectedResponseError] the server has returned a non-2xx response.
    def get path, params = {}
      response = client.send(:get, path, params)
      if response.success?
        return response.body
      else
        raise UnexpectedResponseError.new response
      end
    end

    # @return [Faraday::Client] HTTP client used by this instance.
    # It's already configured with server base url.
    # If a user has been authenticated (see {#login}) the HTTP client
    # will automatically attach authentication headers.
    def client
      @client ||= Faraday.new @options
    end

    private

    def parse_login_response res
      if res.success?
        self.api_key = res.body
      elsif res.status == 401
        raise CredentialError
      else
        raise UnexpectedResponseError.new res
      end
    end
  end
end
