require 'spec_helper'

describe Conjur::API, api: :dummy do
  describe '#create_resource' do
    it "passes to resource#create" do
      api.stub(:resource).with(:id).and_return(resource = double)
      resource.should_receive :create

      api.create_resource(:id).should == resource
    end
  end

  describe '#resource' do
    it "builds a path and creates a resource from it" do
      res = api.resource "some-account:a-kind:the-id"
      res.url.should == "#{authz_host}/some-account/resources/a-kind/the-id"
    end
  end

  describe '.resources' do
    it "lists all resources" do
      ids = %w(acc:kind:foo acc:chunky:bar)
      expect(Conjur::Resource).to receive(:all)
        .with(host: authz_host, credentials: api.credentials).and_return(ids)

      expect(api.resources.map(&:url)).to eql(ids.map { |id| api.resource(id).url })
    end

    it "can filter by kind" do
      ids = %w(acc:chunky:foo acc:chunky:bar)
      expect(Conjur::Resource).to receive(:all)
        .with(host: authz_host, credentials: api.credentials, kind: :chunky).and_return(ids)

      expect(api.resources(kind: :chunky).map(&:url)).to eql(ids.map { |id| api.resource(id).url })
    end
  end
end
