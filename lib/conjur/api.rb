require 'conjur/env'
require 'conjur/base'
require 'conjur/build_from_response'
require 'conjur/acts_as_resource'
require 'conjur/acts_as_role'
require 'conjur/acts_as_user'
require 'conjur/log_source'
require 'conjur/has_attributes'
require 'conjur/has_identifier'
require 'conjur/has_id'
require 'conjur/acts_as_asset'
require 'conjur/authn-api'
require 'conjur/authz-api'
require 'conjur/core-api'
require 'conjur-api/version'

class RestClient::Resource
  include Conjur::Escape
  include Conjur::LogSource
  extend  Conjur::BuildFromResponse

  def core_conjur_account
    Conjur::Core::API.conjur_account
  end
  
  def to_json(options = {})
    {}
  end
  
  def path_components
    require 'uri'
    URI.parse(self.url).path.split('/').map{|e| URI.unescape e}
  end
  
  def username
    options[:user] || options[:username]
  end
end