require 'spec_helper'
require 'standard_methods_helper'

describe Conjur::API, api: :dummy do
  before do
    # The standard test setup doesn't do this
    allow(Conjur.configuration).to receive(:appliance_url).and_return 'https://example.com/api'
  end

  let(:response_json){
    {
        'services' => {
            'authn' => {
                'version' => '4.5.0-75-gde404a6'
            }
        }
    }
  }
  let(:response){ double('response', body: response_json.to_json) }

  describe '+appliance_info' do
    subject{ Conjur::API.appliance_info }
    context 'when /info does not exist' do
      it 'raises a FeatureNotAvailable exception' do
        expect_request(
            method: :get,
            url: 'https://example.com/info'
        ).and_raise RestClient::ResourceNotFound
        expect{ subject }.to raise_error(Conjur::FeatureNotAvailable)
      end
    end

    context 'when /info exists' do
      it 'returns the response json' do
        expect_request(
            method: :get,
            url: 'https://example.com/info'
        ).and_return response

        expect(subject).to eq(response_json)
      end
    end
  end

  describe '+service_names' do
    subject{ Conjur::API.service_names }
    it 'returns the service names' do
      expect_request(
          method: :get,
          url: 'https://example.com/info'
      ).and_return response
      expect(subject).to eq(%w(authn))
    end
  end

  describe '+service_version' do
    subject{ Conjur::API.service_version(service)}
    context 'when the service name is valid' do
      let(:service){'authn'}
      let(:expected_version){ '4.5.0-75-gde404a6'.to_version }
      it 'returns the version as a Semantic::Version' do
        expect_request(
            method: :get,
            url: 'https://example.com/info'
        ).at_least(1).times.and_return response
        expect(subject).to eq(expected_version)
      end
    end

    context 'when the service name is not valid' do
      let(:service){'blahblah'}
      it 'raises an exception' do
        expect_request(
            method: :get,
            url: 'https://example.com/info'
        ).at_least(1).times.and_return response
        expect{ subject }.to raise_error(RuntimeError, /Unknown service/i)
      end
    end
  end
end