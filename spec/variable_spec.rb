require 'spec_helper'
require 'helpers/request_helpers'

describe Conjur::Variable do
  include RequestHelpers
  let(:url) { "http://example.com/variable" }
  subject(:variable) { Conjur::Variable.new url }

  before { subject.attributes = {'version_count' => 42} }

  describe '#version_count' do
    it "is read from the attributes" do
      expect(variable.version_count).to eq(42)
    end
  end

  describe '#add_value' do
    it "posts the new value" do
      expect_request(
        method: :post,
        url: "#{url}/values",
        payload: { value: 'new-value' },
        headers: {}
      )
      subject.add_value 'new-value'
    end
  end

  describe '#value' do
    it "gets the value" do
      allow_request(
        method: :get,
        url: "#{url}/value",
        headers: {}
      ).and_return(double "response", body: "the-value")
      expect(subject.value).to eq("the-value")
    end

    it "parameterizes the request with a version" do
      allow_request(
        method: :get,
        url: "#{url}/value?version=42",
        headers: {}
      ).and_return(double "response", body: "the-value")
      expect(subject.value(42)).to eq("the-value")
    end

    it 'will show the latest expired version' do
      allow_request(
        :method => :get,
        :url => "#{url}/value?show_expired=true",
        :headers => {}
        ).and_return(double('response', :body => 'the-value'))
      expect(subject.value(nil, true)).to eq('the-value')
    end
    
    it 'will show some other version, even if expired' do
      allow_request(
        :method => :get,
        # Hash.to_query (used to build the query string for this
        # request) sorts the params into lexicographic order
        :url => "#{url}/value?show_expired=true&version=42",
        :headers => {}
        ).and_return(double('response', :body => 'the-value'))
      expect(subject.value(42, true)).to eq('the-value')
    end

  end

  describe '#expire' do
    context 'when duration is a number of seconds' do
      let (:expiration) { 2.weeks }
      it 'posts the expiration' do
        expect_request(
          :method => :post,
          :url => "#{url}/expiration",
          :payload => { :duration => "PT#{expiration.to_i}S" },
          :headers => {}
          ).and_return(double('response', :body => '{}'))
        
        subject.expires_in expiration
      end
    end

    context 'when duration is an ISO8601 duration' do
      let (:expiration) { "P2W" }
      it 'posts the expiration' do
        expect_request(
          :method => :post,
          :url => "#{url}/expiration",
          :payload => { :duration => "P2W" },
          :headers => {}
          ).and_return(double('response', :body => '{}'))
        
        subject.expires_in expiration
      end
    end

  end

end
