# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'cgi'
require 'json'

module Conjur
  class API
    # Authenticator that uses a GCP identity token to obtain Conjur access tokens.
    # Fetches an identity JWT from the GCP Instance Metadata Service, then POSTs it
    # to the Conjur authn-gcp endpoint.
    #
    # authn-gcp is a serviceless authenticator: there is no service ID, and Conjur
    # identifies the calling host from the token's claims (matched against the
    # host's authn-gcp/project-id annotation), so the host id is not sent in the
    # authenticate URL.
    #
    # An explicit JWT may be supplied to bypass the metadata service fetch —
    # useful in CI environments where the token is pre-fetched on a GCP agent.
    class GCPAuthenticator
      include TokenExpiration

      DEFAULT_METADATA_URL = 'http://metadata.google.internal/computeMetadata/v1' \
                             '/instance/service-accounts/default/identity'.freeze

      attr_reader :account, :identity, :jwt, :gcp_identity_url

      def initialize(account, identity, jwt: nil,
                     gcp_identity_url: DEFAULT_METADATA_URL)
        @account          = account
        @identity         = identity
        @jwt              = jwt
        @gcp_identity_url = gcp_identity_url
        update_token_born
      end

      def refresh_token
        Conjur::API.authenticate_gcp(identity, account: account,
                                               jwt: jwt,
                                               gcp_identity_url: gcp_identity_url).tap do
          update_token_born
        end
      end
    end

    class << self
      # Create a {Conjur::API} instance authenticated via GCP workload identity (authn-gcp).
      #
      # @param [String] identity Conjur host identity (e.g. "host/data/test/gcp-apps/test-app").
      #   Used to build the metadata-service audience; Conjur itself derives the
      #   host from the token, so it is not sent in the authenticate request.
      # @param [String] account the Conjur organization account
      # @param [String, nil] jwt pre-obtained GCP identity token; when supplied the metadata
      #   service is not called. Useful in tests and CI where the token is pre-fetched.
      # @param [String] gcp_identity_url override for the GCP metadata identity URL (for tests)
      # @param [String, nil] remote_ip optional IP address recorded in the audit log
      # @return [Conjur::API]
      def new_from_gcp(identity,
                       account: Conjur.configuration.account,
                       jwt: nil,
                       gcp_identity_url: GCPAuthenticator::DEFAULT_METADATA_URL,
                       remote_ip: nil)
        self.new.init_from_gcp(identity, account: account,
                                         jwt: jwt, gcp_identity_url: gcp_identity_url,
                                         remote_ip: remote_ip)
      end

      # Authenticate via authn-gcp and return a parsed Conjur access token.
      #
      # @param [String] identity Conjur host identity (used to build the audience)
      # @param [String] account the Conjur organization account
      # @param [String, nil] jwt pre-obtained GCP identity token
      # @param [String] gcp_identity_url override for the GCP metadata identity URL
      # @return [Hash] parsed access token
      def authenticate_gcp(identity,
                           account: Conjur.configuration.account,
                           jwt: nil,
                           gcp_identity_url: GCPAuthenticator::DEFAULT_METADATA_URL)
        raise ArgumentError, "identity is required" if identity.nil? || identity.empty?

        if Conjur.log
          Conjur.log << "Authenticating #{identity} to account #{account} via authn-gcp\n"
        end

        token = jwt || fetch_gcp_jwt(account, identity, gcp_identity_url: gcp_identity_url)
        JSON.parse(url_for(:authn_gcp_authenticate, account)
          .post("jwt=#{CGI.escape(token)}", content_type: 'application/x-www-form-urlencoded'))
      end

      private

      # Fetches a GCP identity token from the instance metadata service.
      # Uses a direct Net::HTTP connection (proxy addr = nil) because the metadata
      # link-local address must never be routed through a proxy.
      #
      # The requested audience is "conjur/{account}/host/{identity}", matching what
      # the authn-gcp authenticator expects.
      def fetch_gcp_jwt(account, identity, gcp_identity_url:)
        aud = gcp_audience(account, identity)
        url = "#{gcp_identity_url}?#{URI.encode_www_form(audience: aud, format: 'full')}"

        uri  = URI(url)
        http = Net::HTTP.new(uri.host, uri.port, nil) # nil = no proxy
        response = http.get(uri.request_uri, 'Metadata-Flavor' => 'Google')

        unless response.is_a?(Net::HTTPSuccess)
          raise "GCP metadata token request failed: #{response.code} #{response.message}. Body: #{response.body}"
        end

        token = response.body&.strip
        raise "GCP metadata service returned an empty token" if token.nil? || token.empty?

        token
      end

      # Builds the authn-gcp audience for a Conjur host identity, e.g.
      # "conjur/myorg/host/data/app". The "host/" prefix is optional in the
      # supplied identity and is normalized away before being re-applied.
      def gcp_audience(account, identity)
        normalized = identity.start_with?('host/') ? identity['host/'.length..] : identity
        "conjur/#{account}/host/#{normalized}"
      end
    end

    def init_from_gcp(identity,
                      account: Conjur.configuration.account,
                      jwt: nil,
                      gcp_identity_url: GCPAuthenticator::DEFAULT_METADATA_URL,
                      remote_ip: nil)
      @remote_ip     = remote_ip
      @authenticator = GCPAuthenticator.new(account, identity,
                                             jwt: jwt, gcp_identity_url: gcp_identity_url)
      self
    end
  end
end
