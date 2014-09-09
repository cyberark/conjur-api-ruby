require 'spec_helper'

describe Conjur::Deputy, api: :dummy do
  let(:api_key) { 'theapikey' }

  subject(:deputy) { Conjur::Deputy.new 'http://example.com/deputies/my%2Fhostname', nil }
  before { deputy.attributes = { 'api_key' => api_key } }

  describe '#resource' do
    subject { deputy.resource }
    it { is_expected.to be }
  end

  describe '#login' do
    it "is extracted from the uri" do
      expect(deputy.login).to eq('deputy/my/hostname')
    end
  end

  describe '#api_key' do
    it "is extracted from attributes" do
      expect(deputy.api_key).to eq api_key
    end
  end
end
