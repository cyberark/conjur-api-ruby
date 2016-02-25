module Conjur
  module Bootstrap
    module Command
      Base = Struct.new(:api, :listener) do
        def echo msg
          listener.echo msg
        end
        
        def security_admin
          api.group("security_admin")
        end
        
        def auditors
          api.group("auditors")
        end
        
        def find_or_create_record record, owner = nil, &block
          if record.exists?
            echo "#{record.resource_kind.capitalize} '#{record.id}' already exists"
            record
          else
            echo "Creating #{record.resource_kind} '#{record.id}'"
            options = {}
            options[:ownerid] = owner.roleid if owner
            result = if block_given?
              yield record, options
            else
              api.send "create_#{record.resource_kind}", record.id, options
            end
            store_api_key result if result.attributes['api_key']
            result
          end
        end

        def find_or_create_resource resource, owner = nil
          if resource.exists?
            echo "#{resource.resource_kind.capitalize} '#{resource.identifier}' already exists"
          else
            echo "Creating #{resource.resource_kind} '#{resource.identifier}'"
            options = {}
            options[:ownerid] = owner.roleid if owner
            api.create_resource resource.resourceid, options
          end
        end
        
        def store_api_key user
          api.create_variable "text/plain", 
            "conjur-api-key", 
            id: "conjur/#{user.resource_kind.pluralize}/#{user.id}/api-key", 
            value: user.api_key,
            ownerid: security_admin.role.roleid
          echo "The API of #{user.resource_kind} #{user.id} is stored in variable 'conjur/#{user.resource_kind.pluralize}/#{user.id}/api-key'. " +
            "You can retire the variable if you don't want to keep it there."
        end
        
        def permit resource, privilege, role
          if resource.permitted_roles(privilege).member?(role.roleid)
            echo "#{role.roleid} already has '#{privilege}' privilege on #{resource.resourceid}"
          else
            resource.permit privilege, role
          end
        end
      end
      
      class SecurityAdminGroup < Base
        def perform
          find_or_create_record security_admin

          security_admin.resource.give_to(security_admin) unless security_admin.resource.ownerid == security_admin.role.roleid
        end
      end

      class AuditorsGroup < Base
        def perform
          find_or_create_record auditors, security_admin
        end
      end
      
      class Pubkeys < Base
        def perform
          find_or_create_record key_managers, security_admin
          find_or_create_record pubkeys_layer, security_admin
          find_or_create_record pubkeys_host, security_admin do |record, options|
            api.create_host(id: record.id, ownerid: security_admin.roleid)
          end
          pubkeys_layer.add_host pubkeys_host unless pubkeys_layer.hosts.map(&:roleid).member?(pubkeys_host.roleid)
          
          find_or_create_resource pubkeys_service, security_admin
          permit pubkeys_service, 'update', key_managers
        end
        
        def pubkeys_layer
          api.layer("pubkeys-1.0/public-keys")
        end
        
        def pubkeys_host
          api.host("conjur/pubkeys")
        end
        
        def pubkeys_service
          api.resource("service:pubkeys-1.0/public-keys")
        end
        
        def key_managers
          api.group("pubkeys-1.0/key-managers")
        end
      end
      
      class Attic < Base
        def perform
          find_or_create_record attic
        end
        
        def attic_user_name
          "attic"
        end
        
        def attic
          api.user(attic_user_name)
        end
      end
      
      class AuthnTV < Base
        def perform
          find_or_create_resource tv_service, security_admin
        end
        
        def tv_service
          api.resource("webservice:conjur/authn-tv")
        end
      end
      
      # Create a set of hosts that have security_admin privilege.
      class SystemAccounts < Base
        def perform
          for hostname in %w(conjur/secrets-rotator conjur/policy-loader conjur/ldap-sync)
            find_or_create_record api.host(hostname), security_admin do |record, options|
              api.create_host(id: record.id, ownerid: security_admin.roleid).tap do |host|
                host.role.revoke_from security_admin
                security_admin.add_member host
              end
            end
          end
        end
      end
      
      class GlobalPrivileges < Base
        def perform
          permit conjur_resource, 'elevate', security_admin
          permit conjur_resource, 'reveal', security_admin
          permit conjur_resource, 'reveal', auditors
        end
        
        def conjur_resource
          api.resource("!:!:conjur")
        end
      end
    end
  end
end
