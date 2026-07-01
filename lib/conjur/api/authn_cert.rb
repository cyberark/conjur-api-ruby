# frozen_string_literal: true

require 'openssl'
require 'json'

module Conjur
  class API
    # Authenticator that uses mutual TLS (authn-cert) to obtain Conjur access tokens.
    # The client certificate is presented during the TLS handshake; an empty POST
    # to the authn-cert endpoint returns a Conjur access token.
    #
    # Two modes:
    # - Request mode: +host_id+ is provided; Conjur validates the cert matches the host.
    # - SPIFFE mode:  +host_id+ is nil; Conjur derives the host from the cert's SPIFFE SAN URI.
    class CertAuthenticator
      include TokenExpiration

      attr_reader :account, :service_id, :cert, :key, :host_id

      def initialize(account, service_id, cert, key, host_id = nil)
        @account    = account
        @service_id = service_id
        @cert       = cert
        @key        = key
        @host_id    = host_id
        update_token_born
      end

      def refresh_token
        Conjur::API.authenticate_cert(service_id, cert, key, account: account, host_id: host_id).tap do
          update_token_born
        end
      end
    end

    class << self
      # Create a new {Conjur::API} instance authenticated via client certificate (authn-cert / mTLS).
      #
      # The +cert+ and +key+ arguments may each be:
      # * An already-loaded OpenSSL object (+OpenSSL::X509::Certificate+ / +OpenSSL::PKey::PKey+)
      # * A file path (String) — the file will be read and parsed
      # * A PEM-encoded string — parsed directly
      #
      # @param [String] service_id the authn-cert service ID configured in Conjur
      # @param [OpenSSL::X509::Certificate, String] cert client certificate
      # @param [OpenSSL::PKey::PKey, String] key client private key
      # @param [String] account The organization account.
      # @param [String, nil] host_id Conjur host path for request mode (e.g. "host/workloads/vm-01").
      #   Pass +nil+ or omit for SPIFFE mode.
      # @param [String, nil] remote_ip optional IP address recorded in the audit log.
      # @return [Conjur::API]
      def new_from_cert(service_id, cert, key,
                        account: Conjur.configuration.account,
                        host_id: nil,
                        remote_ip: nil)
        cert = load_cert(cert)
        key  = load_key(key)
        self.new.init_from_cert(service_id, cert, key,
                                account: account, host_id: host_id, remote_ip: remote_ip)
      end

      # Authenticate using authn-cert and return a parsed Conjur access token.
      #
      # +cert+ and +key+ must already be OpenSSL objects (use {.new_from_cert} for automatic loading).
      #
      # @param [String] service_id the authn-cert service ID
      # @param [OpenSSL::X509::Certificate] cert client certificate
      # @param [OpenSSL::PKey::PKey] key client private key
      # @param [String] account The organization account.
      # @param [String, nil] host_id Conjur host path for request mode; nil for SPIFFE mode.
      # @return [Hash] parsed access token
      def authenticate_cert(service_id, cert, key,
                            account: Conjur.configuration.account,
                            host_id: nil)
        if Conjur.log
          Conjur.log << "Authenticating via authn-cert/#{service_id} to account #{account}\n"
        end
        cert_options = { ssl_client_cert: cert, ssl_client_key: key }
        JSON.parse(url_for(:authn_cert_authenticate, account, service_id, host_id, cert_options).post(''))
      end

      private

      def load_cert(cert)
        return cert if cert.is_a?(OpenSSL::X509::Certificate)
        pem = File.file?(cert.to_s) ? File.read(cert.to_s) : cert.to_s
        OpenSSL::X509::Certificate.new(pem)
      end

      def load_key(key)
        return key if key.is_a?(OpenSSL::PKey::PKey)
        pem = File.file?(key.to_s) ? File.read(key.to_s) : key.to_s
        OpenSSL::PKey.read(pem)
      end
    end

    def init_from_cert(service_id, cert, key,
                       account: Conjur.configuration.account,
                       host_id: nil,
                       remote_ip: nil)
      @remote_ip     = remote_ip
      @authenticator = CertAuthenticator.new(account, service_id, cert, key, host_id)
      self
    end
  end
end
