require 'conjur/layer'

module Conjur
  class API
    #@!group Directory: Layers


    # Create a new layer with the given id
    #
    # @example
    #   # create a new layer named 'webservers'
    #   webservers = api.create_layer 'webservices'
    #
    #   # create layer is *not* idempotent
    #   api.create_layer 'webservices' # raises RestClient::Conflict
    #
    #   # create a layer owned by user 'alice'
    #   api.create_layer 'webservices', ownerid: 'alice'
    #   api.owner # => 'conjur:user:alice'
    #
    # @param [String] id an *unqualified* id for the layer.
    # @return [Conjur::Layer]
    def create_layer(id, options = {})
      standard_create Conjur::API.layer_asset_host, :layer, id, options
    end

    # Get all layers visible to the current role
    #
    # @param [Hash] options TODO doc options
    # @return [Array<Conjur::Layer>] all layers
    def layers(options = {})
      standard_list Conjur::API.layer_asset_host, :layer, options
    end


    # Get a layer by its *unqualified id*.
    #
    # Like other Conjur methods, this will return a {Conjur::Layer} whether
    # or not the record is found, and you must use the {Conjur::Exists#exists?} method
    # to check this.
    #
    # @example
    #   api.create_layer id: 'foo'
    #   foo = api.layer "foo" # => returns a Conjur::Layer
    #   puts foo.resourceid # => "conjur:layer:foo"
    #   puts foo.id # => "foo"
    #   mistake = api.layer "doesnotexist" # => Also returns a Conjur::Layer
    #   foo.exists? # => true
    #   mistake.exists? # => false
    #
    # @param [String] id the unqualified id of the layer
    # @return [Conjur::Layer] an object representing the layer, which may or may not exist.
    def layer id
      standard_show Conjur::API.layer_asset_host, :layer, id
    end
  end
end
