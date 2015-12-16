require 'spec_helper'
require 'standard_methods_helper'
require 'cidr_helper'

describe Conjur::API, api: :dummy do
  describe '::enroll_host' do
    it "uses Net::HTTP to get something" do
      response = double "response",
          code: '200', body: 'foobar'
      allow(response).to receive(:[]).with('Content-Type').and_return 'text/whatever'

      url = URI.parse "http://example.com"
      allow(Net::HTTP).to receive(:get_response).with(url).and_return response

      expect(Conjur::API.enroll_host("http://example.com")).to eq(['text/whatever', 'foobar'])
    end
  end

  describe '#create_host' do
    it_should_behave_like "standard_create with", :host, nil, some: :options do
      let(:invoke) { subject.create_host some: :options }
    end

    include_examples 'CIDR create' do
      def create opts
        api.create_host opts
      end
    end
  end

  describe '#host' do
    it_should_behave_like "standard_show with", :host, :id do
      let(:invoke) { subject.host :id }
    end
  end
end
