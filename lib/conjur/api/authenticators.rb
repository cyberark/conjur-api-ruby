# frozen_string_literal: true

require 'conjur/webservice'

module Conjur
  # API contains each of the methods for access the Conjur API endpoints
  #-- :reek:DataClump for authenticator identifier fields (name, id, account)
  class API
    # @!group Authenticators

    # List all configured authenticators
    def authenticator_list
      JSON.parse(url_for(:authenticators).get)
    end

    # Fetches the available authentication providers for the authenticator and account.
    # The authenticators must be loaded in Conjur policy prior to fetching.
    #
    # @param [String] authenticator the authenticator type to retrieve providers for
    def authentication_providers(authenticator, account: Conjur.configuration.account)
      JSON.parse(url_for(:authentication_providers, account, authenticator, credentials).get)
    end

    # Enables an authenticator in Conjur. The authenticator must be defined and
    # loaded in Conjur policy prior to enabling it.
    # 
    # @param [String] authenticator the authenticator type to enable (e.g. authn-k8s)
    # @param [String] id the service ID of the authenticator to enable
    def authenticator_enable authenticator, id, account: Conjur.configuration.account
      url_for(:authenticator, account, authenticator, id, credentials).patch(enabled: true)
    end

    # Disables an authenticator in Conjur.
    # 
    # @param [String] authenticator the authenticator type to disable (e.g. authn-k8s)
    # @param [String] id the service ID of the authenticator to disable
    def authenticator_disable authenticator, id, account: Conjur.configuration.account
      url_for(:authenticator, account, authenticator, id, credentials).patch(enabled: false)
    end

    # @!endgroup
  end
end
