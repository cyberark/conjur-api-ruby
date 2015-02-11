require 'spec_helper'
require 'standard_methods_helper'

describe Conjur::API, api: :dummy do
  subject { api }

  describe '#groups' do
    it_should_behave_like 'standard_list with', :group, :options do
      let(:invoke) { subject.groups :options }
    end
  end

  describe '#create_group' do
    it_should_behave_like 'standard_create with', :group, :id, :options do
      let(:invoke) { subject.create_group :id, :options }
    end

    it_should_behave_like 'standard_create with', :group, :id, gidnumber: 371509 do
      let(:invoke) { subject.create_group :id, gidnumber: 371509 }
    end
  end

  describe '#group' do
    it_should_behave_like 'standard_show with', :group, :id do
      let(:invoke) { subject.group :id }
    end
  end

  describe '#find_groups' do
    it "searches the group by GID" do
      expect(RestClient::Request).to receive(:execute).with(
        method: :get,
        url: "#{core_host}/groups/search?gidnumber=12345",
        headers: credentials[:headers]
      ).and_return ['foo'].to_json

      expect(api.find_groups(gidnumber: 12345)).to eq(['foo'])
    end
  end
end
