# Copyright (C) 2013-2016 Conjur Inc.
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
#
require 'semantic'
require 'semantic/core_ext'
module Conjur
  class API
    class << self

      # Return the version of the given service presently running on the Conjur appliance.
      #
      # @example Check that the authn service is at least version 4.6
      #   if api.service_version('authn') >= '4.6.0'.to_version
      #     puts "Authn version is at least 4.6.0"
      #   end
      #
      # This feature is useful for determining whether the Conjur appliance has a particular feature.
      #
      # If the given service does not exist, this method will raise an exception.  To retrieve a list of
      # valid service names, you can use `Conjur::API.service_names`
      #
      # @param [String] service the name of the service.
      # @return [Semantic::Version] the version of the service.
      def service_version service
        if (service_info = appliance_info['services'][service]).nil?
          raise "Unknown service #{service} (services are #{service_names.join(', ')}."
        else
          # Pre-release versions are discarded, because they make testing harder:
          # 2.0.0-p598 :004 > Semantic::Version.new("4.5.0") <= Semantic::Version.new("4.5.0-1")
          # => false
          major, minor, patch, pre = service_info['version'].split(/[.-]/)[0..3]
          Semantic::Version.new "#{major}.#{minor}.#{patch}"
        end
      end

      # Return an Array of valid service names for your appliance.
      #
      # @return [Array<String>] the names of services on the appliance.
      def service_names
        appliance_info['services'].keys
      end

      # Return a Hash containing various information about the Conjur appliance.
      #
      # If the appliance does not support this feature, raise Conjur::FeatureNotAvailable.
      #
      # @note This feature requires Conjur appliance version 4.6 or above.
      #
      # @return [Hash] various information about the Conjur appliance.
      def appliance_info
        JSON.parse(RestClient::Resource.new(appliance_info_url).get.body)
      rescue RestClient::ResourceNotFound
        raise Conjur::FeatureNotAvailable.new('Your appliance does not support the /info URL needed by Conjur::API.appliance_info (you need 4.6 or later)')
      end

      # Return a Hash containing health information for this appliance, or for another host.
      #
      # If the `remote_host` argument is provided, the health of that appliance is reported from
      # the perspective of the appliance being queried (as specified by the `appliance_url` configuration
      # variable).
      #
      # @note When called without an argument, this method requires a Conjur server running version 4.5 or later.
      #   When called with an argument, it requires 4.6 or later.
      #
      # @param [String, NilClass] remote_host a hostname for a remote host
      # @return [Hash] the appliance health information.
      def appliance_health remote_host=nil
        remote_host.nil? ? own_health : remote_health(remote_host)
      end

      private


      def remote_health host
        JSON.parse(RestClient::Resource.new(remote_health_url(host)).get.body)
      rescue RestClient::ResourceNotFound
        raise Conjur::FeatureNotAvailable.new('Your appliance does not support the /remote_health/:host URL needed by Conjur::API.appliance_health (you need 4.6 or later)')
      rescue RestClient::ExceptionWithResponse => ex
        JSON.parse(ex.response.body)
      end


      def own_health
        JSON.parse(RestClient::Resource.new(appliance_health_url).get.body)
      rescue RestClient::ResourceNotFound
        raise Conjur::FeatureNotAvailable.new('Your appliance does not support the /health URL needed by Conjur::API.appliance_health (you need 4.5 or later)')
      rescue RestClient::ExceptionWithResponse => ex
        JSON.parse(ex.response.body)
      end

      def remote_health_url host
        raw_appliance_url "/remote_health/#{fully_escape host}"
      end

      def appliance_health_url
        raw_appliance_url '/health'
      end

      def appliance_info_url
        raw_appliance_url '/info'
      end

      def raw_appliance_url path
        url = Conjur.configuration.appliance_url
        raise "Conjur connection is not configured" unless url
        url.gsub(%r{/api$}, path)
      end
    end
  end
end