class Conjur::API
  class << self
    # @api private
    #
    # Url to the layers service.
    # @return [String] the url
    def layer_asset_host
      ENV["CONJUR_LAYER_ASSET_URL"] || Conjur::Core::API.host
    end
  end
end

require 'conjur/api/layers'
