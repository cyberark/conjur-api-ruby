require 'conjur/env'
require 'conjur/base'
require 'conjur/acts_as_resource'
require 'conjur/has_attributes'
require 'conjur/has_identifier'
require 'conjur/das-api'
require 'conjur/authn-api'
require 'conjur/authz-api'
require 'conjur/core-api'

class RestClient::Resource
  include Conjur::Escape
end