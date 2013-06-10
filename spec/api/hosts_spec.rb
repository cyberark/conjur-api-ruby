require 'spec_helper'

describe Conjur::API, api: :dummy do
  subject { api }

  describe '::enroll_host' do
    it "uses Net::HTTP to get something" do
      response = double "response",
          code: '200', body: 'foobar'
      response.stub(:[]).with('Content-Type').and_return 'text/whatever'

      url = URI.parse "http://example.com"
      Net::HTTP.stub(:get_response).with(url).and_return response

      Conjur::API.enroll_host("http://example.com").should == ['text/whatever', 'foobar']
    end
  end

  let(:core_host) { 'http://core.example.com' }
  before { Conjur::Core::API.stub host: core_host }

  describe '#create_host' do
    it "passes along to standard_create" do
      subject.should_receive(:standard_create).with(
        core_host, :host, nil, :options
      ).and_return :response
      subject.create_host(:options).should == :response
    end
  end

  describe '#host' do
    it "passes to standard_show" do
      subject.should_receive(:standard_show).with(
        core_host, :host, :id
      ).and_return :response
      subject.host(:id).should == :response
    end
  end
end
