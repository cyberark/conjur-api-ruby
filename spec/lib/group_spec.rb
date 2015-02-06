require 'spec_helper'

describe Conjur::Group, api: :dummy do
  let(:id) { 'the-anonymous' }
  subject { api.group id }

  describe '#update' do
    it "PUTs to /groups/:id?gidnumber=:gidnumber" do
      expect(RestClient::Request).to receive(:execute).with(
        method: :put,
        url: "#{core_host}/groups/#{api.fully_escape(id)}",
        headers: credentials[:headers],
        payload: { gidnumber: 12345 }
       )
      api.group(id).update(gidnumber: 12345)
    end
  end
end
