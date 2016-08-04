#
# Copyright (C) 2016 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to

# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'spec_helper'
require 'helpers/request_helpers'

describe Conjur::API, api: :dummy do
  include RequestHelpers
  describe 'LDAP Sync methods' do
    let(:appliance_url){ "http://example.com/api" }

    describe '#ldap_sync_now' do
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
      let(:dry_run) { true }

      before do
        allow(Conjur.configuration).to receive(:appliance_url).and_return appliance_url
        allow(Conjur::API).to receive_messages(ldap_sync_now: ldapsync_url)
        expect_request(
            url: ldapsync_url,
            method: :post,
            headers: credentials[:headers],
            payload: {config_name: 'default', dry_run: dry_run}
        ).and_return response
      end

      context 'with dry_run expected to be true' do
        let(:dry_run){ true }


        it "POSTs /sync" do
          api.ldap_sync_now('default', 'application/json', true)
        end

        it "POSTs /sync with truthy dry_run value" do
          api.ldap_sync_now('default', 'application/json', 1)
        end
      end

      context 'with dry_run expected to be false' do
        let(:dry_run){ false }

        it "POSTs /sync with dry_run set to false" do
          api.ldap_sync_now('default', 'application/json', false)
        end

        it "POSTs /sync with falsey dry_run value" do
          api.ldap_sync_now('default', 'application/json', nil)
        end
      end

    end
  end
end
