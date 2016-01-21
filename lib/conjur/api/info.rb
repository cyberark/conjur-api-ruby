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
      #   if api.service_version('authn') >= '4.6'.to_version
      #     puts "Authn version is at least 4.6"
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
          service_info['version'].to_version
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
        raise Conjur::FeatureNotAvailable.new('Your appliance does not support the /info URL needed by Conjur::API#appliance_info (you need 4.6 or later)')
      end

      private
      
      def appliance_info_url
        Conjur.configuration.appliance_url.gsub(%r{/api$}, '/info')
      end
    end
  end
end