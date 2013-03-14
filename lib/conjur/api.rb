require 'conjur/env'
require 'conjur/base'
require 'conjur/acts_as_resource'
require 'conjur/acts_as_role'
require 'conjur/acts_as_user'
require 'conjur/log_source'
require 'conjur/has_attributes'
require 'conjur/has_identifier'
require 'conjur/has_id'
require 'conjur/authn-api'
require 'conjur/authz-api'
require 'conjur/core-api'

class RestClient::Resource
  include Conjur::Escape
  include Conjur::LogSource
  
  def username
    options[:user] || options[:username]
  end
end