class Conjur::API
  class << self
    def layer_asset_host
      ENV["CONJUR_LAYER_ASSET_URL"] || Conjur::Core::API.host
    end
  end
end

require 'conjur/api/layers'
