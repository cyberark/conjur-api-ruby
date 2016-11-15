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
  describe 'LDAP policy methods' do
    let(:appliance_url){ "http://example.com/api" }
    before do
      allow(Conjur.configuration).to receive(:appliance_url).and_return appliance_url
    end

    describe '#ldap_sync_policy' do
      let(:profile) { 'default' }
      let(:url){ "#{appliance_url}/ldap-sync/policy?config_name=#{profile}" }
      let(:policy_event){
        %Q{data: {"policy": "a policy"}}
      }

      let(:response){ double('response', :body => policy_event, :headers => { :content_type => 'text/event-stream' }) }
      subject{ api.ldap_sync_policy('default') }
      before do
        expect_request(
            url: url,
            method: :get,
            headers: credentials[:headers]
        ).and_return response
      end

      it 'returns a Hash with a policy' do
        expect(subject).to be_kind_of Hash
      end
    end

  end
end
