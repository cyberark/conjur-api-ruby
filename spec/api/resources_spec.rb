require 'spec_helper'
require 'helpers/request_helpers'

describe Conjur::API, api: :dummy do
  include RequestHelpers

  describe '#create_resource' do
    it "passes to resource#create" do
      allow(api).to receive(:resource).with(:id).and_return(resource = double)
      expect(resource).to receive :create

      expect(api.create_resource(:id)).to eq(resource)
    end
  end

  describe '#resource' do
    it "builds a path and creates a resource from it" do
      res = api.resource "some-account:a-kind:the-id"
      expect(res.url).to eq("#{authz_host}/some-account/resources/a-kind/the-id")
    end
    it "accepts an account-less resource" do
      res = api.resource "a-kind:the-id"
      expect(res.url).to eq("#{authz_host}/#{account}/resources/a-kind/the-id")
    end
    it "rejects an underspecified resource" do
      expect { api.resource "the-id" }.to raise_error(/at least two tokens in the-id/)
    end
  end

  describe '.resources' do
    let(:ids) { %w(acc:kind:foo acc:chunky:bar) }
    let(:resources) {
      ids.map do |id|
        { 'id' => id }
      end
    }
    it "counts resources" do
      expect(Conjur::Resource).to receive(:all)
        .with(host: authz_host, account: account, credentials: api.credentials, count: true).and_return(100)

      expect(api.resources(count: true)).to eq(100)
    end
    it "lists all resources" do
      expect(Conjur::Resource).to receive(:all)
        .with(host: authz_host, account: account, credentials: api.credentials).and_return(resources)

      expect(api.resources.map(&:url)).to eql(ids.map { |id| api.resource(id).url })
    end
    it "can filter by kind" do
      expect(Conjur::Resource).to receive(:all)
        .with(host: authz_host, account: account, credentials: api.credentials, kind: :chunky).and_return(resources)

      expect(api.resources(kind: :chunky).map(&:url)).to eql(ids.map { |id| api.resource(id).url })
    end
  end

  describe '#resources_permitted' do
    let(:ids) { %w(foo bar baz) }
    let(:kind) { 'variable' }
    let(:priv) { 'execute' }

    it 'creates the request correctly' do
      expect_request(
        method: :post,
        url: "#{authz_host}/the-account/resources/#{kind}?check=true",
        payload: {
          :privilege => priv,
          :identifiers => ids
        }
      ).and_return(double("response", :code => 204))
      
      res = api.resources_permitted?(kind, ids, priv)
      expect(res[0]).to be(true)
    end

    it 'signals failure' do
      expect_request(
        method: :post,
        url: "#{authz_host}/the-account/resources/#{kind}?check=true",
        payload: {
          :privilege => priv,
          :identifiers => ids
        }
      ).and_return(double("response", :code => 403, :body => '[]'))
      
      res = api.resources_permitted?(kind, ids, priv)
      expect(res[0]).to be(false)
    end

  end
  
end
