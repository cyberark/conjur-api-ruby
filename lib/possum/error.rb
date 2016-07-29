module Possum
  # Base class of errors thrown by the Possum client.
  class Error < ::RuntimeError
  end

  # Credential error, caused by eg. a bad password, nonexistent user or
  # expired API key.
  class CredentialError < Error
  end

  # Error raised when the server returns an unexpected response.
  class UnexpectedResponseError < Error
    def initialize response
      @response = response
    end

    # @return [Faraday::Response] response that has been unexpected
    attr_reader :response

    # @return [String] message stating the status and body of the response
    def to_s
      "Unexpected response: #{response.status} #{response.body}"
    end
  end
end
