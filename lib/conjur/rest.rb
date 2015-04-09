#
# Copyright (C) 2015 Conjur Inc
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

require 'rest-client'
require 'conjur/build_from_response'
require 'conjur/cast'
require 'conjur/escape'
require 'conjur/log_source'
require 'conjur/patches/rest-client'
require 'conjur-api/version'

module Conjur
# A REST resource with Conjur-related functionality.
# Base for all REST references in the library.
  class REST < RestClient::Resource
    # Instance methods separated into a module to support compatibility code.
    # Please roll back into REST class on 5.0.
    module InstanceMethods
      include Conjur::Cast
      include Conjur::Escape
      include Conjur::LogSource

      def default_options
        {
          verify_ssl: true,
          ssl_cert_store: OpenSSL::SSL::SSLContext::DEFAULT_CERT_STORE
        }
      end

      def core_conjur_account
        Conjur::Core::API.conjur_account
      end

      def to_json _options = {}
        {}
      end

      def conjur_api
        Conjur::API.new_from_token token
      end

      def token
        authorization = options[:headers][:authorization]
        if authorization && (token = authorization.to_s[/^Token token="(.*)"/, 1])
          JSON.parse(Base64.decode64(token))
        else
          fail AuthorizationError, "Authorization missing"
        end
      end

      def username
        options[:user] || options[:username]
      end

      # can be removed after rolling back this module into Conjur::REST
      def self.included base
        Conjur::Escape.included base
      end
    end

    # deprecation warning handling code
    # can be removed after dropping the compatibility code below
    class << self
      def show_deprecation_warning
        return if Conjur::API::VERSION < "4.15.0" # give people some time to upgrade
        gem = find_deprecated_gem caller_locations(2, 1).first.absolute_path
        return unless gem && gem.name =~ /conjur-asset/
        $stderr.puts """
WARNING: Deprecated direct call to RestClient::Resource instead of Conjur::REST
from #{caller(3, ENV['DEBUG'] ? nil : 1).join("\n")}.

Please update the #{gem.name} gem.
        """
      end

      # make sure path really is appropriate for deprecation warning,
      # that we haven't warned already about this file and find the gem it
      # belongs to
      def find_deprecated_gem path
        return if path == __FILE__
        return unless (gem = gem_of_file path)
        return if (@deprecation_warnings ||= []).include? path
        @deprecation_warnings << path
        gem
      end

      # tries to find gem of the file at given path by searching for
      # successively longer suffixes
      def gem_of_file path
        components = path.split('/')
        (1..components.length).map do |suffix_len|
          components[-suffix_len..-1].join('/')
        end.map(&Gem::Specification.method(:find_by_path)).compact.first
      end
    end

    # Uncomment after removing compatibility code
    #
    # def initialize url, options = nil, &block
    #   super url, default_options.merge(options || {}), &block
    # end

    include InstanceMethods
    extend Conjur::BuildFromResponse
  end
end

if Conjur::API::VERSION >= '5'
  fail 'please remove deprecated code from lib/conjur/rest.rb'
else
  # deprecated monkey patch for the benefit of old plugins
  class RestClient::Resource
    include Conjur::REST::InstanceMethods
    extend Conjur::BuildFromResponse

    alias_method :initialize_without_conjur_deprecation, :initialize

    def initialize url, options = nil, &block
      Conjur::REST.show_deprecation_warning
      initialize_without_conjur_deprecation url, default_options.merge(options || {}), &block
    end
  end
end
