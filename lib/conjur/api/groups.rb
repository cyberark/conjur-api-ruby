require 'conjur/group'

module Conjur
  class API
    def groups(options={})
      standard_list Conjur::Core::API.host, :group, options
    end

    def create_group(id, options = {})
      standard_create Conjur::Core::API.host, :group, id, options
    end

    def group id
      standard_show Conjur::Core::API.host, :group, id
    end
  end
end