require 'spec_helper'

describe Conjur::API, api: :dummy do
  let(:router) { double('router', :get => "{}") }
  before do
    allow_any_instance_of(Conjur::API).to receive(:url_for).with(:ldap_sync_policy, any_args).and_return(router)
  end

  # verify that the method exists, and takes the correct argument.
  describe '#ldap_sync_policy' do
    context 'with default config' do
      subject { api.ldap_sync_policy }
      it { is_expected.to eq({})  }
    end

    context 'with a config specified' do
      subject { api.ldap_sync_policy config_name: 'non-default-config' }
      it { is_expected.to eq({}) }
    end
  end
end
