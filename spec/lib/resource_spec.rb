require 'spec_helper'
require 'helpers/request_helpers'

describe Conjur::Resource, api: :dummy, logging: :temp do
  include RequestHelpers

  let(:account) { "the-account" }
  let(:uuid) { "ddd1f59a-494d-48fb-b045-0374c4a6eef9" }

  context "identifier" do
    include Conjur::Escape
    let(:resource) { Conjur::Resource.new("#{Conjur.configuration.core_url}/#{account}/resources/#{kind}/#{path_escape identifier}") }

    context "Object with an #id" do
      let(:kind) { "host" }
      let(:identifier) do
        "foobar"
      end
      it "identifier should obtained from the id" do
        expect(resource.identifier).to eq("foobar")
      end
    end

    [ [ "foo", "bar/baz" ], [ "f:o", "bar" ], [ "@f", "bar.baz" ], [ "@f", "bar baz" ], [ "@f", "@:bar/baz" ] ].each do |p|
      context "of /#{p[0]}/#{p[1]}" do
        let(:kind) { p[0] }
        let(:identifier) { p[1] }
        context "resource_kind" do
          subject { resource.kind }
          specify { is_expected.to eq(p[0]) }
        end
        context "resource_id" do
          subject { resource.identifier }
          specify { is_expected.to eq( p[1] ) }
        end
      end
    end
  end

  let(:uri) { "#{authz_host}/some-account/resources/the-kind/resource-id" }
  subject { Conjur::Resource.new uri }

  describe '#create' do
    it "simply puts" do
      expect_request(
        method: :put,
        url: uri,
        payload: {},
        headers: {}
      ).and_return "new resource"
      expect(subject.create).to eq("new resource")
    end
  end

  describe '#permitted_roles' do
    it 'gets the list from /roles/allowed_to' do
      expect_request(
        method: :get,
        url: "http://authz.example.com/some-account/roles/allowed_to/nuke/the-kind/resource-id",
        headers: {}
      ).and_return '["foo", "bar"]'

      expect(subject.permitted_roles("nuke")).to eq(['foo', 'bar'])
    end

    it 'supports counting' do
      expect_request(
        method: :get,
        url: "http://authz.example.com/some-account/roles/allowed_to/nuke/the-kind/resource-id?count=true",
        headers: {}
      ).and_return({count: 12}.to_json)

      expect(subject.permitted_roles("nuke", count: true)).to eq(12)
    end

    it 'supports filtering' do
      expect_request(
        method: :get,
        url: "http://authz.example.com/some-account/roles/allowed_to/nuke/the-kind/resource-id?search=hamsters",
        headers: {}
      ).and_return '["foo", "bar"]'

      expect(subject.permitted_roles("nuke", search: 'hamsters')).to eq(['foo', 'bar'])
    end
  end

  describe '#give_to' do
    it "puts the owner field" do
      expect_request(
        method: :put,
        url: uri,
        payload: {owner: 'new-owner' },
        headers: {}
      )

      subject.give_to 'new-owner'
    end
  end

  describe '#delete' do
    it 'simply deletes' do
      expect_request(
        method: :delete,
        url: uri,
        headers: {}
      )

      subject.delete
    end
  end

  describe '#permit' do
    it 'posts permit for every privilege' do
      privileges = [:nuke, :fry]
      privileges.each do |p|
        expect_request(
          method: :post,
          url: uri + "/?permit&privilege=#{p}&role=dr-strangelove",
          headers: {},
          payload: {}
        )
      end
      subject.permit privileges, "dr-strangelove"
    end
  end

  describe '#deny' do
    it 'posts deny for every privilege' do
      privileges = [:nuke, :fry]
      privileges.each do |p|
        expect_request(
          method: :post,
          url: uri + "/?deny&privilege=#{p}&role=james-bond",
          headers: {},
          payload: {}
        )
      end
      subject.deny privileges, "james-bond"
    end
  end

  describe '#permitted?' do
    it 'gets the ?permitted? action' do
      expect_request(
        method: :get,
        url: uri + "/?check=true&privilege=fry",
        headers: {}
      )
      subject.permitted? 'fry'
    end
    context "with status 204" do
      before {
        allow(subject).to receive_message_chain(:[], :get)
      }
      specify {
        expect(subject.permitted?('fry')).to be_truthy
      }
    end
    context "with status 404" do
      before {
        allow(subject).to receive_message_chain(:[], :get) { raise RestClient::ResourceNotFound }
      }
      specify {
        expect(subject.permitted?('fry')).to be_falsey
      }
    end
    context "with status 403" do
      before {
        allow(subject).to receive_message_chain(:[], :get) { raise RestClient::Forbidden }
      }
      specify {
        expect(subject.permitted?('fry')).to be_falsey
      }
    end
  end

  describe '.all' do
    it "calls /account/resources" do
      expect_request(
        method: :get,
        url: "http://authz.example.com/the-account/resources/",
        headers: {}
      ).and_return '["foo", "bar"]'

      expect(Conjur::Resource.all host: authz_host, account: account).to eql(%w(foo bar))
    end

    it "can filter by owner" do
      expect_request(
        method: :get,
        url: "http://authz.example.com/the-account/resources/chunky/?owner=alice",
        headers: {}
      ).and_return '["foo", "bar"]'

      expect(Conjur::Resource.all host: authz_host, account: account, kind: :chunky, owner: 'alice')
        .to eql(%w(foo bar))
    end

    it "can filter by kind" do
      expect_request(
        method: :get,
        url: "http://authz.example.com/the-account/resources/chunky/",
        headers: {}
      ).and_return '["foo", "bar"]'

      expect(Conjur::Resource.all host: authz_host, account: account, kind: :chunky)
        .to eql(%w(foo bar))
    end
    
    it "can count" do
      expect_request(
        method: :get,
        url: "http://authz.example.com/the-account/resources/?count=true",
        headers: {}
      ).and_return({count: 12}.to_json)

      expect(Conjur::Resource.all host: authz_host, account: account, count: true).to eq(12)
    end

    it "passes search, limit, and offset params" do
      expect_request(
        method: :get,
        # Note that to_query sorts the keys
        url: "http://authz.example.com/the-account/resources/?limit=5&offset=6&search=something",
        headers: {}
      ).and_return '["foo", "bar"]'
      expect(Conjur::Resource.all(host: authz_host, account: account, search: 'something', limit:5, offset:6)).to eq(%w(foo bar))
    end

    it "uses the given authz url" do
      expect_request(
        method: :get,
        url: "http://otherhost.example.com/the-account/resources/",
        headers: {}
      ).and_return '["foo", "bar"]'

      Conjur::Resource.all host: 'http://otherhost.example.com', account: account
    end
  end
end
