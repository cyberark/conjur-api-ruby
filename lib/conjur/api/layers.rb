require 'conjur/layer'

module Conjur
  class API
    def create_layer(id, options = {})
      standard_create Conjur::API.layer_asset_host, :layer, id, options
    end
    
    def layers(options = {})
      standard_list Conjur::API.layer_asset_host, :layer, options
    end
    
    def layer id
      standard_show Conjur::API.layer_asset_host, :layer, id
    end
  end
end
