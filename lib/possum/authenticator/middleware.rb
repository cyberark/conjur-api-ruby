require 'faraday'

module Possum
  class Authenticator
    # Faraday middleware adding Conjur authentication tokens.
    # @note Automatically used internally by {Possum::Client}.
    class Middleware < Faraday::Middleware
      # Create a new instance of the middleware.
      # @param [#call] app The underlying middleware stack.
      # @param [Authenticator] Possum authenticator to use as a source of tokens.
      def initialize app = nil, authenticator = nil
        super(app)
        @authenticator = authenticator
      end

      def call request_env
        request_env[:request_headers].merge! \
            'Authorization' => %Q(Token token="#{@authenticator.token}") \
            if @authenticator

        @app.call request_env
      end
    end
  end
end

Faraday::Request.register_middleware possum_authenticator: Possum::Authenticator::Middleware
