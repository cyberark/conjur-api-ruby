#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require 'active_support/core_ext/string/inflections'
require 'conjur/env'
require 'conjur-api/version'
require 'conjur/log'
puts "required conjur/api"
module Conjur
  def self.const_missing name
    case name
      when :API
        %w(base audit-api authn-api authz-api core-api api/authn).each do |file|
          require "conjur/#{file}"
        end
      when :Authn, :Authz, :Core, :Audit
        require 'conjur/base'
        require "conjur/#{name.to_s.downcase}-api"
      when :RestClient
        require 'conjur/base'
      else
        return super name
    end
    return const_get(name) if const_defined?(name)
    super name
  end

  %w(acts_as_asset acts_as_resource acts_as_role acts_as_user annotations
     build_from_response cast configuration deputy escape event_source
     exists group has_attributes has_id has_identifier has_owner host
     log_source path_based resource role role_grant secret standard_methods
     user variable
  ).each do |file|
    autoload file.camelize.to_sym,  "conjur/#{file}"
  end


  class << self
    def configuration
      @config ||= Configuration.new
    end

    def configuration=(config)
      @config = config
    end
  end

end
