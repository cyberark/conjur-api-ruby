module Conjur
  module ActsAsResource
    def resource
      require 'conjur/resource'
      Conjur::Resource.new("#{Conjur::Authz::API.host}/#{path_escape resource_kind}/#{path_escape resource_id}", credentials)
    end
    
    def resource_kind
      class_name = self.class.name.split("::")[-1].downcase
      [ "conjur", class_name ].join("-")
    end

    def resource_id
      identifier
    end

    def delete
      resource.delete
      self.delete
    end
  end
end