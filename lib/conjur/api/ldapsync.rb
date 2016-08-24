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

    # Trigger a LDAP sync with a given profile.
    #
    # @param [Array] args If first element is a Hash, use it as the parameters for the /sync call. Otherwise, assume the caller is using the old calling convention.
    # @return [Hash] a hash mapping with keys 'ok' and 'result[:actions]'
    def ldap_sync_now(*args)
      
      # Be backward compatible....
      # This is kind of gross, but changing the interface for this
      # method didn't seem worth a major version bump.
      if args[0].instance_of?(Hash)
        options = args[0]
      else
        options = {}
        options[:config],options[:format],options[:dry_run] = args[0..2]
        # Old callers expect /sync to be synchronous
        options[:detach_job] = false
      end

      opts = credentials.dup.tap{ |h|
        h[:headers][:accept] = options[:format]
      }

      options[:dry_run] = !!options[:dry_run]

      resp = RestClient::Resource.new(Conjur.configuration.appliance_url, opts)['ldap-sync']['sync'].post(options)

      case options[:format]
      when 'text/yaml'
        resp.body
      when 'application/json'
        JSON.parse(resp.body)
      end
    end

    # Return a list of detached ldap sync jobs
    def ldap_sync_jobs
      resource = RestClient::Resource.new(Conjur.configuration.appliance_url, credentials)
      response = resource['ldap-sync']['jobs'].get

      JSON.parse(response.body).map do |job_hash|
        Conjur::LdapSyncJob.new_from_json(self, job_hash)
      end
    end

  # @!endgroup
  end
end
