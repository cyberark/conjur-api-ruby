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
      JSON.parse(get_json("policy", response)).merge('events' => find_log_events(response))
    end

    # @api private
    # Get an LDAP sync profile.

    # @param [String] profile name 
    # @param [Hash] options reserved
    def ldap_sync_show_profile(profile, options = {})
      url = Conjur.configuration.appliance_url
      resp = RestClient::Resource.new(url, credentials)['ldap-sync']['config'][profile].get(options)
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
    def ldap_sync_update_profile(profile_name, profile, options = {})
      options[:json_config] = profile.to_json
      resp = RestClient::Resource.new(Conjur.configuration.appliance_url, credentials)['ldap-sync']['config'][profile_name].put(options.to_json, :content_type => 'application/json')
      JSON.parse(resp.body)
    end

    # @api private
    # Search using an LDAP sync profile
    #
    # @param [String] profile name
    # @param [Hash] options reserved
    def ldap_sync_search(profile, options = {})
      headers = credentials.dup.tap {|h|
        h[:headers][:accept] = 'text/event-stream'
      }

      response = RestClient::Resource.new(Conjur.configuration.appliance_url, headers)['ldap-sync']['search'].post(options.merge(:config_name => profile))
      JSON.parse(get_json("groups", response)).merge('events' => find_log_events(response))
    end

    # @!endgroup
    
    private
    def get_json(key, response)
      if response.headers[:content_type] == 'text/event-stream'
        find_event_by_key(key, response) || find_error_events(response)
      else
        %Q({"error": {"message": "Unexpected response from server: #{response.body}"}})
      end    
    end

    def find_event_by_key(key, response)
      response.body.lines.find {|l| l =~ %r(^data: {"#{key}":) }.try(:[], 6..-1)
    end

    def find_log_events(response)
      find_events(response, 'log').collect { |e| JSON.parse(e)['log'] }
    end

    def find_error_events(response)
      find_events(response, "error").join("\n")
    end

    def find_events(response, key)
      response.body.lines.collect {|l| l.match(/^data: ({"#{key}":.*)/).try(:[], 1)}.compact
    end
  end
end
