module Conjur
  class API
    module Router
      module V4
        extend Conjur::Escape
        extend Conjur::QueryString
        extend self

        def authn_login account, username, password
          verify_account(account)
          RestClient::Resource.new(Conjur::Authn::API.host, user: username, password: password)['users/login']
        end

        protected

        def verify_account account
          raise "Expecting account to be #{Conjur.configuration.account.inspect}, got #{account.inspect}" unless Conjur.configuration.account == account
        end
      end
    end
  end
end
