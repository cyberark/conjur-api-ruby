module Possum
  # Possum authenticator, responsible for keeping track of token validity
  # and fetching new ones as necessary.
  #
  # @see ApiKeyAuthenticator
  class Authenticator
    # @return [String] encoded Possum authentication token.
    def token
      @current_token = fetch_token unless token_ready?
      @current_token
    end

    # @return [Boolean] whether an unexpired token is currently stored.
    def token_ready?
      @current_token && (!token_expired?)
    end

    # @return [Boolean] whether the token currently stored has expired.
    def token_expired?
      (token_age || 0) > TOKEN_STALE
    end

    # Set current token.
    # This is used internally but also useful when you have an external token
    # source.
    # @param [String] token The token in encoded form.
    def token= token
      @current_token = token
      @token_born = self.class.gettime
    end

    # Fetch a new token.
    # In this base implementation, simply return the current one,
    # @see ApiKeyAuthenticator
    def fetch_token
      @current_token
    end

    private

    TOKEN_STALE = 7 * 60

    def token_age
      @token_born && (self.class.gettime - @token_born)
    end

    def self.gettime
      Process.clock_gettime Process::CLOCK_MONOTONIC
    rescue
      # fall back to normal clock if there's no CLOCK_MONOTONIC
      Time.now.to_f
    end
  end
end
