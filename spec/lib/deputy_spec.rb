require 'spec_helper'

describe Conjur::Deputy, api: :dummy do
  subject { Conjur::Deputy.new 'http://example.com/deputies/my%2Fhostname', nil }

  describe '#resource' do
    subject { super().resource }
    it { is_expected.to be }
  end

  describe '#login' do
    subject { super().login }
    it { is_expected.to eq('deputy/my/hostname') }
  end

  let(:api_key) { 'theapikey' }
  before { subject.attributes = { 'api_key' => api_key } }

  describe '#api_key' do
    subject { super().api_key }
    it { is_expected.to eq(api_key) }
  end
end
