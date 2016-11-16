#
# Copyright (C) 2016 Conjur Inc
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
require 'conjur/ldap_sync_job'

module Conjur
  class API
    # @!group LDAP Sync Service

    # Fetch a Conjur policy that will bring Conjur into sync with the
    # LDAP server specified by a profile.
    #
    # @param [String] profile the name of the LDAP server profile 
    # @param [Hash] options reserved for future use
    def ldap_sync_policy profile, options = {}
      
      headers = credentials.dup.tap {|h|
        h[:headers][:accept] = 'text/event-stream'
      }

      options = options.merge(:config_name => profile)
      url = Conjur.configuration.appliance_url + "/ldap-sync/policy?#{options.to_query}"

      # Even though we're using SSE to return the policy, fetch the
      # whole thing at once into a single response. Retrieving it in
      # chunks doesn't buy us much of anything except more complicated
      # client code.
      response = RestClient::Resource.new(url, headers).get

      json = if response.headers[:content_type] == 'text/event-stream'
               find_policy_event(response) || find_error_events(response)
             else
               %Q({"error": {"message": "Unexpected response from server: #{response.body}"}})
             end
      JSON.parse(json)
    end

    # @api private
    # Get an LDAP sync profile.

    # @param [String] profile name 
    # @param [Hash] options reserved
    def ldap_sync_show_profile(profile, options = {})
      resp = RestClient::Resource.new(Conjur.configuration.appliance_url, credentials)['ldap-sync']['config'].get(options)
      JSON.parse(resp.body)
    end

    # @api private
    # Update an LDAP sync profile. 
    #
    # ### Note
    # DO NOT use this method and the UI to update an LDAP sync profile.
    #
    # @param [Hash] profile a hash containing the LDAP sync configuration
    # @param [Hash] options reserved
    def ldap_sync_update_profile(profile, options = {})
      options[:json_config] = profile.to_json
      resp = RestClient::Resource.new(Conjur.configuration.appliance_url, credentials)['ldap-sync']['config'].put(options.to_json, :content_type => 'application/json')
      JSON.parse(resp.body)
    end

    # @!endgroup
    
    private
    def find_policy_event(response)
      response.body.lines.find {|l| l =~ /^data: {"policy":/}.try(:[], 6..-1)
    end

    def find_error_events(response)
      response.body.lines.collect {|l| l.match(/^data: ({"error":.*)/).try(:[], 1)}.compact.join("\n")
    end

  end
end
