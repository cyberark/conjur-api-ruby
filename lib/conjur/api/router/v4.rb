module Conjur
  class API
    module Router
      module V4
        extend Conjur::Escape::ClassMethods
        extend Conjur::QueryString
        extend self

        def authn_login account, username, password
          verify_account(account)
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)['users/login']
        end

        def authn_authenticate account, username
          verify_account(account)
          RestClient::Resource.new(Conjur.configuration.authn_url)['users'][fully_escape username]['authenticate']
        end

        def authn_rotate_api_key credentials, account, id
          verify_account(account)
          username = if id.kind == "user"
            id.identifier
          else
            [ id.kind, id.identifier ].join('/')
          end
          RestClient::Resource.new(Conjur.configuration.authn_url, credentials)['users']["api_key?id=#{username}"]
        end

        def authn_rotate_own_api_key account, username, password
          verify_account(account)
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)['users']["api_key"]
        end

        def host_factory_create_host token
          http_options = {
            headers: { authorization: %Q(Token token="#{token}") }
          }
          RestClient::Resource.new(Conjur.configuration.core_url, http_options)['host_factories']['hosts']
        end

        def host_factory_create_tokens credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['host_factories'][id.identifier]['tokens']
        end

        def resources_resource credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['authz'][id.account]['resources'][id.kind][id.identifier]
        end

        def roles_role credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['authz'][id.account]['roles'][id.kind][id.identifier]
        end

        protected

        def verify_account account
          raise "Expecting account to be #{Conjur.configuration.account.inspect}, got #{account.inspect}" unless Conjur.configuration.account == account
        end
      end
    end
  end
end
