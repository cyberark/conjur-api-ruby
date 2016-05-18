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
#

module Conjur
  class API
  # @!group LDAP Sync Service

    # Trigger a LDAP sync with a given profile.

    # @param [String] config_name Saved profile to run sync with
    # @param [Boolean] dry_run Don't actually run sync, report actions to be performed
    # @param [String] format Output format to return, 'text' or 'json'
    def ldap_sync_now(config_name, dry_run, format)
      resp = RestClient::Resource.new("#{Conjur.configuration.appliance_url}/ldap-sync/sync", credentials).post({
        config_name: config_name,
        dry_run: dry_run,
        format: format
      })
      puts resp
    end

  # @!endgroup
  end
end
