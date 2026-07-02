# frozen_string_literal: true

require 'net/http'
require 'json'
require 'uri'
require 'cgi'

module Conjur
  class API
    # Authenticator that uses an Azure Managed Identity JWT to obtain Conjur access tokens.
    # Fetches a JWT from the Azure Instance Metadata Service (IMDS), then POSTs it
    # to the Conjur authn-azure endpoint.
    class AzureAuthenticator
      include TokenExpiration

      IMDS_TOKEN_PATH    = '/metadata/identity/oauth2/token'.freeze
      DEFAULT_RESOURCE   = 'https://management.azure.com/'.freeze
      DEFAULT_IMDS_BASE  = 'http://169.254.169.254'.freeze
      DEFAULT_IMDS_VER   = '2018-02-01'.freeze

      attr_reader :account, :service_id, :identity, :resource_uri,
                  :client_id, :imds_base_url, :imds_api_version

      def initialize(account, service_id, identity,
                     resource_uri: DEFAULT_RESOURCE,
                     client_id: nil,
                     imds_base_url: DEFAULT_IMDS_BASE,
                     imds_api_version: DEFAULT_IMDS_VER)
        @account          = account
        @service_id       = service_id
        @identity         = identity
        @resource_uri     = resource_uri
        @client_id        = client_id
        @imds_base_url    = imds_base_url
        @imds_api_version = imds_api_version
        update_token_born
      end

      def refresh_token
        Conjur::API.authenticate_azure(service_id, identity,
                                       account: account,
                                       resource_uri: resource_uri,
                                       client_id: client_id,
                                       imds_base_url: imds_base_url,
                                       imds_api_version: imds_api_version).tap do
          update_token_born
        end
      end
    end

    class << self
      # Create a {Conjur::API} instance authenticated via Azure Managed Identity (authn-azure).
      #
      # @param [String] service_id the authn-azure service ID configured in Conjur
      # @param [String] identity Conjur host identity (e.g. "host/my-app/azure-host")
      # @param [String] account the Conjur organization account
      # @param [String] resource_uri Azure resource URI for the IMDS token request
      # @param [String, nil] client_id optional client ID for a user-assigned managed identity
      # @param [String] imds_base_url override for the IMDS base URL (useful in tests)
      # @param [String] imds_api_version override for the IMDS API version
      # @param [String, nil] remote_ip optional IP address recorded in the audit log
      # @return [Conjur::API]
      def new_from_azure(service_id, identity,
                         account: Conjur.configuration.account,
                         resource_uri: AzureAuthenticator::DEFAULT_RESOURCE,
                         client_id: nil,
                         imds_base_url: AzureAuthenticator::DEFAULT_IMDS_BASE,
                         imds_api_version: AzureAuthenticator::DEFAULT_IMDS_VER,
                         remote_ip: nil)
        self.new.init_from_azure(service_id, identity,
                                 account: account,
                                 resource_uri: resource_uri,
                                 client_id: client_id,
                                 imds_base_url: imds_base_url,
                                 imds_api_version: imds_api_version,
                                 remote_ip: remote_ip)
      end

      # Authenticate via authn-azure and return a parsed Conjur access token.
      #
      # @param [String] service_id the authn-azure service ID
      # @param [String] identity Conjur host identity
      # @param [String] account the Conjur organization account
      # @return [Hash] parsed access token
      def authenticate_azure(service_id, identity,
                             account: Conjur.configuration.account,
                             resource_uri: AzureAuthenticator::DEFAULT_RESOURCE,
                             client_id: nil,
                             imds_base_url: AzureAuthenticator::DEFAULT_IMDS_BASE,
                             imds_api_version: AzureAuthenticator::DEFAULT_IMDS_VER)
        raise ArgumentError, "service_id is required" if service_id.nil? || service_id.empty?
        raise ArgumentError, "identity is required"   if identity.nil?  || identity.empty?

        if Conjur.log
          Conjur.log << "Authenticating #{identity} to account #{account} via authn-azure/#{service_id}\n"
        end

        jwt = fetch_azure_jwt(resource_uri: resource_uri, client_id: client_id,
                              imds_base_url: imds_base_url, imds_api_version: imds_api_version)
        JSON.parse(url_for(:authn_azure_authenticate, account, service_id, identity)
          .post("jwt=#{CGI.escape(jwt)}", content_type: 'application/x-www-form-urlencoded'))
      end

      private

      # Fetches an Azure Managed Identity JWT from IMDS.
      # Uses a direct Net::HTTP connection (proxy addr = nil) because the IMDS
      # link-local address 169.254.169.254 must never be routed through a proxy.
      def fetch_azure_jwt(resource_uri:, client_id:, imds_base_url:, imds_api_version:)
        query = "api-version=#{CGI.escape(imds_api_version)}&resource=#{CGI.escape(resource_uri)}"
        query += "&client_id=#{CGI.escape(client_id)}" if client_id

        uri = URI("#{imds_base_url}#{AzureAuthenticator::IMDS_TOKEN_PATH}?#{query}")
        http = Net::HTTP.new(uri.host, uri.port, nil) # nil = no proxy
        response = http.get(uri.request_uri, 'Metadata' => 'true')

        unless response.is_a?(Net::HTTPSuccess)
          raise "Azure IMDS token request failed: #{response.code} #{response.message}. Body: #{response.body}"
        end

        body = JSON.parse(response.body)
        token = body['access_token']
        raise "Azure IMDS returned an empty access token" if token.nil? || token.empty?

        token
      end
    end

    def init_from_azure(service_id, identity,
                        account: Conjur.configuration.account,
                        resource_uri: AzureAuthenticator::DEFAULT_RESOURCE,
                        client_id: nil,
                        imds_base_url: AzureAuthenticator::DEFAULT_IMDS_BASE,
                        imds_api_version: AzureAuthenticator::DEFAULT_IMDS_VER,
                        remote_ip: nil)
      @remote_ip     = remote_ip
      @authenticator = AzureAuthenticator.new(account, service_id, identity,
                                               resource_uri: resource_uri,
                                               client_id: client_id,
                                               imds_base_url: imds_base_url,
                                               imds_api_version: imds_api_version)
      self
    end
  end
end
