module Conjur
  module Provider
    def provider_method method, *args
      send "v#{Conjur.configuration.major_version}_#{method}", *args
    end

    protected

    def v5_authn_login_resource account, username, password
      RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)[fully_escape account]['login']
    end

    def v5_authn_authenticate_resource account, username
      RestClient::Resource.new(Conjur.configuration.authn_url)[fully_escape account][fully_escape username]['authenticate']
    end

    def v5_authn_update_password_resource account, username, password
      RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)[fully_escape account]['password']
    end

    def v5_authn_rotate_api_key_resource account, username, password
      RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)[fully_escape account]['api_key']
    end

    def v4_authn_login_resource account, username, password
      verify_account(account)
      RestClient::Resource.new(Conjur::Authn::API.host, user: username, password: password)['users/login']
    end

    def verify_account account
      raise "Expecting account to be #{Conjur.configuration.account.inspect}, got #{account.inspect}" unless Conjur.configuration.account == account
    end
  end
end
