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
    before do
      allow(Conjur.configuration).to receive(:appliance_url).and_return appliance_url
    end

    describe '#ldap_sync_jobs' do
      let(:url){ "#{appliance_url}/ldap-sync/jobs" }
      let(:response_json){
        [
            { 'id' => 'job-1', 'exclusive' => false, 'type' => 'connect', 'state' => 'success'},
            { 'id' => 'job-2', 'exclusive' => true, 'type' => 'sync', 'state' => 'running'},
            { 'id' => 'job-3', 'exclusive' => false, 'type' => 'search', 'state' => 'success'}
        ]
      }

      let(:response){ double('response', body: response_json.to_json) }
      subject{ api.ldap_sync_jobs }
      before do
        expect_request(
            url: url,
            method: :get,
            headers: credentials[:headers]
        ).and_return response
      end

      it 'returns an Array of LdapSyncJob objects with the appropriate fields' do
        expect(subject).to be_kind_of Array
        expect(subject.length).to eq(response_json.length)
        expect(subject[0].id).to eq('job-1')
        expect(subject[1].exclusive?).to be(true)
        expect(subject[2].type).to eq('search')
        expect(subject[0].state).to eq('success')
      end
    end

    describe 'LdapSyncJob#delete' do
      let(:job){ Conjur::LdapSyncJob.new(api, :id => 'job-id', :exclusive => false, :type => 'connect', :state => 'running') }
      let(:url){ "#{appliance_url}/ldap-sync/jobs/#{job.id}" }

      it 'calls delete on the job resource' do
        expect_request(
            url: url,
            method: :delete,
            headers: credentials[:headers]
        )
        job.delete
      end

    end

    describe 'LdapSyncJob#output' do

      let(:response){ double('response', code: response_status.to_s) }

      let(:chunks){[
          'id:', " 0\n",
          "event: foo\ndata: {\"message\": \"hello\"",  "}\n\n",
          'id: 1', "\nevent: result\ndata: {\"ok\":false,\"error\":{\"message\":\"Cannot resolve host ldapserver\"}}\n\n"
      ]}

      let(:job){
        Conjur::LdapSyncJob.new(api, :id => 'job-id', :exclusive => false, :type => 'connect', :state => 'running')
      }

      let(:url){ "#{appliance_url}/ldap-sync/jobs/#{job.id}/output" }

      before do
        expect_request(
            url: url,
            method: :get,
            headers: credentials[:headers].dup.merge(accept: 'text/event-stream'),
            block_response: instance_of(Proc)
        ) do |opts|
          opts[:block_response].call response
        end
        expect(response).to receive(:read_body) do |&blk|
          chunks.each{ |c| blk[c] }
        end
      end

      context 'when the request succeeds' do

        let(:response_status){ 200 }

        context 'when given a block' do
          it 'is called with each event' do
            blocked = []
            events = job.output do |event|
              blocked << event
            end
            expect(blocked.length).to eq(2)
            expect(blocked).to eq(events)
          end
        end

        context 'when not given a block' do
          it 'returns the event data' do
            events = job.output
            expect(events[0]['message']).to eq('hello')
            expect(events[1]['ok']).to be_falsey
            expect(events[1]['error']['message']).to eq('Cannot resolve host ldapserver')
          end
        end
      end

      context 'when the request fails' do
        let(:response_status){ 422 }

        it 'calls response.error!' do
          expect(response).to receive(:error!)
          job.output
        end
      end
    end

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
      let(:detach_job) { true }
      let(:sync_options) { 
        {
          :config => 'default', 
          :format => 'application/json', 
          :detach_job => detach_job
        }
      }


      before do
        allow(Conjur::API).to receive_messages(ldap_sync_now: ldapsync_url)
        expect_request(
            url: ldapsync_url,
            method: :post,
            headers: credentials[:headers],
            payload: sync_options.merge(dry_run: dry_run)
        ).and_return response
      end

      context 'with dry_run expected to be true' do
        let(:dry_run){ true }

        it "POSTs /sync" do
          api.ldap_sync_now(sync_options.merge(:dry_run => true))
        end

        it "POSTs /sync with truthy dry_run value" do
          api.ldap_sync_now(sync_options.merge(:dry_run => 1))
        end
      end

      context 'with dry_run expected to be false' do
        let(:dry_run){ false }

        it "POSTs /sync with dry_run set to false" do
          api.ldap_sync_now(sync_options.merge(:dry_run => false))
        end

        it "POSTs /sync with falsey dry_run value" do
          api.ldap_sync_now(sync_options.merge(:dry_run => nil))
        end
      end
      
      context 'with the old calling convention' do
        let(:detach_job) { false }
        it 'still works' do
          api.ldap_sync_now(sync_options[:config], sync_options[:format], dry_run)
        end
      end

    end
  end
end
