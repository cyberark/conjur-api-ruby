require 'conjur/env'
require 'conjur/base'
require 'conjur/das-api'
require 'conjur/authn-api'
require 'conjur/authz-api'
require 'conjur/core-api'

class RestClient::Resource
  include Conjur::Escape
end