module Conjur
  class API
    module Router
      module V5
        extend Conjur::Escape::ClassMethods
        extend Conjur::QueryString
        extend self

        def authn_login account, username, password
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)[fully_escape account]['login']
        end

        def authn_authenticate account, username
          RestClient::Resource.new(Conjur.configuration.authn_url)[fully_escape account][fully_escape username]['authenticate']
        end

        def authn_update_password account, username, password
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)[fully_escape account]['password']
        end

        def authn_rotate_api_key account, username, password
          RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: password)[fully_escape account]['api_key']
        end

        def authn_rotate_own_api_key credentials, account, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['authn'][path_escape account]["api_key?role=#{id}"]
        end

        def host_factory_create_host token
          http_options = {
            headers: { authorization: %Q(Token token="#{token}") }
          }
          RestClient::Resource.new(Conjur.configuration.core_url, http_options)["host_factories"]["hosts"]
        end

        def host_factory_create_tokens credentials
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['host_factory_tokens']
        end

        def host_factory_revoke_token credentials, token
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['host_factory_tokens'][token]
        end

        def policies_load_policy credentials, account, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['policies'][path_escape account]['policy'][path_escape id]
        end

        def public_keys_for_user account, username
          RestClient::Resource.new(Conjur.configuration.core_url)['public_keys'][fully_escape account]['user'][path_escape username]
        end

        def resources credentials, account, kind, options
          credentials ||= {}

          path = "/resources/#{path_escape account}" 
          path += "/#{path_escape kind}" if kind

          RestClient::Resource.new(Conjur.configuration.core_url, credentials)[path][options_querystring options]
        end

        def resources_resource credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['resources'][id.to_url_path]
        end

        def roles_role credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['roles'][id.to_url_path]
        end

        def variables_variable credentials, id
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['secrets'][id.to_url_path]
        end

        def variable_values credentials, variable_ids
          opts = "?variable_ids=#{variable_ids.map { |v| fully_escape(v) }.join(',')}"
          RestClient::Resource.new(Conjur.configuration.core_url, credentials)['secrets'+opts]
        end
      end
    end
  end
end
