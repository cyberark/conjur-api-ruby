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
require 'spec_helper'

describe Conjur::API, api: :dummy do
  let(:appliance_url){ "http://example.com/api" }
  let(:ldapsync_url){ "#{appliance_url}/ldap-sync/sync" }
  let(:response_json){
    {
        :okay => true,
        :result => {
            :actions => [
                "Create user 'Guest'\n  Set annotation 'ldap-sync/source'\n  Set annotation 'ldap-sync/upstream-dn'"
            ]
        }
    }
  }
  let(:response){ double('response', body: response_json.to_json) }

  before do
    allow(Conjur.configuration).to receive(:appliance_url).and_return appliance_url
    allow(Conjur::API).to receive_messages(ldap_sync_now: ldapsync_url)
  end

  describe "#ldap_sync_now" do
    it "POSTs /sync" do
      expect_request(
          url: ldapsync_url,
          method: :post,
          headers: credentials[:headers],
          payload: {config_name: 'default', dry_run: true}.to_json
      ).and_return response
      api.ldap_sync_now('default', 'application/json', true)
    end
  end
end
