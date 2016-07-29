require 'faraday'

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

    # @return [String, nil] API key for the Possum service
    # @see login
    attr_reader :api_key

    # Log in to the Possum service by using a password to get an API key.
    # The API key is stored in this client instance and will be used on
    # any further requests.
    #
    # @param [String] username the user name
    # @param [String] password the password
    # @return [String] API key
    # @raise [CredentialError] username or password is incorrect
    # @raise [UnexpectedResponseError] the server has returned an unexpected response
    def login username, password
      res = client.get '/authn/login' do |req|
        req.headers['Authorization'] =
            Faraday::Request::BasicAuthentication.header username, password
      end
      if res.success?
        @api_key = res.body
      elsif res.status == 401
        raise CredentialError
      else
        raise UnexpectedResponseError.new res
      end
    end

    private

    def client
      @client ||= Faraday.new @options
    end
  end
end
