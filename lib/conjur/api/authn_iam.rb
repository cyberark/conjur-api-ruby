# frozen_string_literal: true

require 'json'
require 'uri'

module Conjur
  class API
    # Authenticator that uses AWS IAM credentials to obtain Conjur access tokens.
    # Signs an AWS STS GetCallerIdentity request with SigV4, then POSTs the
    # resulting headers as JSON to the Conjur authn-iam endpoint.
    #
    # Requires the +aws-sdk-core+ gem (not bundled with conjur-api).
    # Add `gem 'aws-sdk-core'` to your Gemfile to use this authenticator.
    class IAMAuthenticator
      include TokenExpiration

      DEFAULT_SERVICE_ID = 'prod'.freeze
      DEFAULT_REGION     = 'us-east-1'.freeze

      STS_GLOBAL_URL  = 'https://sts.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15'.freeze
      STS_REGIONAL_URL = 'https://sts.%<region>s.amazonaws.com/?Action=GetCallerIdentity&Version=2011-06-15'.freeze
      STS_GLOBAL_SIGNING_REGION = 'us-east-1'.freeze

      attr_reader :account, :service_id, :identity, :aws_region

      def initialize(account, service_id, identity, aws_region = DEFAULT_REGION)
        @account    = account
        @service_id = service_id
        @identity   = identity
        @aws_region = aws_region
        update_token_born
      end

      def refresh_token
        Conjur::API.authenticate_iam(identity, account: account,
                                               service_id: service_id,
                                               aws_region: aws_region).tap do
          update_token_born
        end
      end
    end

    class << self
      # Create a {Conjur::API} instance authenticated via AWS IAM (authn-iam).
      #
      # AWS credentials are resolved from the default chain: environment variables
      # (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN), then
      # ~/.aws/credentials, then the EC2 instance profile.
      #
      # Requires the +aws-sdk-core+ gem.
      #
      # @param [String] identity Conjur host identity (e.g. "host/my-app/my-role")
      # @param [String] service_id the authn-iam service ID (default: "prod")
      # @param [String] account the Conjur organization account
      # @param [String] aws_region AWS region for STS signing. Use "global" for the
      #   global STS endpoint (signed as us-east-1).
      # @param [String, nil] remote_ip optional IP address recorded in the audit log
      # @return [Conjur::API]
      def new_from_iam(identity,
                       account: Conjur.configuration.account,
                       service_id: IAMAuthenticator::DEFAULT_SERVICE_ID,
                       aws_region: IAMAuthenticator::DEFAULT_REGION,
                       remote_ip: nil)
        self.new.init_from_iam(identity, account: account, service_id: service_id,
                                         aws_region: aws_region, remote_ip: remote_ip)
      end

      # Authenticate via authn-iam and return a parsed Conjur access token.
      #
      # @param [String] identity Conjur host identity
      # @param [String] service_id the authn-iam service ID
      # @param [String] account the Conjur organization account
      # @param [String] aws_region AWS region for STS signing
      # @return [Hash] parsed access token
      def authenticate_iam(identity,
                           account: Conjur.configuration.account,
                           service_id: IAMAuthenticator::DEFAULT_SERVICE_ID,
                           aws_region: IAMAuthenticator::DEFAULT_REGION)
        raise ArgumentError, "identity is required"   if identity.nil?   || identity.empty?
        raise ArgumentError, "service_id is required" if service_id.nil? || service_id.empty?

        begin
          require 'aws-sdk-core'
        rescue LoadError
          raise LoadError,
                "aws-sdk-core is required for IAM authentication. " \
                "Add `gem 'aws-sdk-core'` to your Gemfile."
        end

        if Conjur.log
          Conjur.log << "Authenticating #{identity} to account #{account} via authn-iam/#{service_id}\n"
        end

        signed_headers = build_iam_signed_headers(aws_region)
        JSON.parse(url_for(:authn_iam_authenticate, account, service_id, identity)
          .post(signed_headers.to_json, content_type: 'application/json'))
      end

      private

      def build_iam_signed_headers(aws_region)
        signing_region = aws_region == 'global' ? IAMAuthenticator::STS_GLOBAL_SIGNING_REGION : aws_region
        sts_url = aws_region == 'global' || aws_region == IAMAuthenticator::STS_GLOBAL_SIGNING_REGION \
          ? IAMAuthenticator::STS_GLOBAL_URL
          : format(IAMAuthenticator::STS_REGIONAL_URL, region: aws_region)

        provider = Aws::CredentialProviderChain.new.resolve
        raise ArgumentError,
              "No AWS credentials found. Configure an instance profile, " \
              "environment variables (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY), " \
              "or ~/.aws/credentials." unless provider

        creds = provider.credentials
        signer = Aws::Sigv4::Signer.new(
          service:           'sts',
          region:            signing_region,
          access_key_id:     creds.access_key_id,
          secret_access_key: creds.secret_access_key,
          session_token:     creds.session_token
        )

        signed = signer.sign_request(http_method: 'GET', url: sts_url, headers: {}, body: '')
        headers = signed.headers.dup
        # Conjur expects these specific keys
        headers['host'] = URI.parse(sts_url).host
        headers.compact
      end
    end

    def init_from_iam(identity,
                      account: Conjur.configuration.account,
                      service_id: IAMAuthenticator::DEFAULT_SERVICE_ID,
                      aws_region: IAMAuthenticator::DEFAULT_REGION,
                      remote_ip: nil)
      @remote_ip     = remote_ip
      @authenticator = IAMAuthenticator.new(account, service_id, identity, aws_region)
      self
    end
  end
end
