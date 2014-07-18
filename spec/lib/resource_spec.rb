require 'spec_helper'

describe Conjur::Resource, api: :dummy, logging: :temp do
  let(:account) { "the-account" }
  let(:uuid) { "ddd1f59a-494d-48fb-b045-0374c4a6eef9" }

  context "identifier" do
    include Conjur::Escape
    let(:resource) { Conjur::Resource.new("#{Conjur::Authz::API.host}/#{account}/resources/#{kind}/#{path_escape identifier}") }

    context "Object with an #id" do
      let(:kind) { "host" }
      let(:identifier) do
        "foobar"
      end
      it "identifier should obtained from the id" do
        resource.identifier.should == "foobar"
      end
    end

    [ [ "foo", "bar/baz" ], [ "f:o", "bar" ], [ "@f", "bar.baz" ], [ "@f", "bar baz" ], [ "@f", "@:bar/baz" ] ].each do |p|
      context "of /#{p[0]}/#{p[1]}" do
        let(:kind) { p[0] }
        let(:identifier) { p[1] }
        context "resource_kind" do
          subject { resource.kind }
          specify { should == p[0] }
        end
        context "resource_id" do
          subject { resource.identifier }
          specify { should == ( p[1] ) }
        end
      end
    end
  end

  let(:uri) { "#{authz_host}/some-account/resources/the-kind/resource-id" }
  subject { Conjur::Resource.new uri }

  describe '#create' do
    it "simply puts" do
      RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: uri,
        payload: {},
        headers: {}
      ).and_return "new resource"
      subject.create.should == "new resource"
    end
  end

  describe '#permitted_roles' do
    it 'gets the list from /roles/allowed_to' do
      RestClient::Request.should_receive(:execute).with(
        method: :get,
        url: "http://authz.example.com/some-account/roles/allowed_to/nuke/the-kind/resource-id",
        headers: {}
      ).and_return '["foo", "bar"]'

      subject.permitted_roles("nuke").should == ['foo', 'bar']
    end
  end

  describe '#give_to' do
    it "puts the owner field" do
      RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: uri,
        payload: {owner: 'new-owner' },
        headers: {}
      )

      subject.give_to 'new-owner'
    end
  end

  describe "#exists" do
    let(:uri) { "#{authz_host}/some-account/resources/the-kind/resource-id" }
    it "sends HEAD /<resource>" do
      RestClient::Request.should_receive(:execute).with(
        method: :head,
        url: uri,
        headers: {}
      )
      subject.exists?
    end
    context "with status 204" do
      before {
        subject.stub(:head)
      }
      its(:exists?) { should be_true }
    end
    context "with status 404" do
      before {
        subject.stub(:head) { raise RestClient::ResourceNotFound }
      }
      its(:exists?) { should be_false }
    end
    context "with status 403" do
      before {
        subject.stub(:head) { raise RestClient::Forbidden }
      }
      its(:exists?) { should be_true }
    end
  end

  describe '#delete' do
    it 'simply deletes' do
      RestClient::Request.should_receive(:execute).with(
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
        RestClient::Request.should_receive(:execute).with(
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
        RestClient::Request.should_receive(:execute).with(
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
      RestClient::Request.should_receive(:execute).with(
        method: :get,
        url: uri + "/?check=true&privilege=fry",
        headers: {}
      )
      subject.permitted? 'fry'
    end
    context "with status 204" do
      before {
        subject.stub_chain(:[], :get)
      }
      specify {
        subject.permitted?('fry').should be_true
      }
    end
    context "with status 404" do
      before {
        subject.stub_chain(:[], :get) { raise RestClient::ResourceNotFound }
      }
      specify {
        subject.permitted?('fry').should be_false
      }
    end
    context "with status 403" do
      before {
        subject.stub_chain(:[], :get) { raise RestClient::Forbidden }
      }
      specify {
        subject.permitted?('fry').should be_false
      }
    end
  end

  describe '.all' do
    it "calls /account/resources" do
      RestClient::Request.should_receive(:execute).with(
        method: :get,
        url: "http://authz.example.com/the-account/resources",
        headers: {}
      ).and_return '["foo", "bar"]'

      expect(Conjur::Resource.all host: authz_host, account: account).to eql(%w(foo bar))
    end

    it "can filter by kind" do
      RestClient::Request.should_receive(:execute).with(
        method: :get,
        url: "http://authz.example.com/the-account/resources/chunky",
        headers: {}
      ).and_return '["foo", "bar"]'

      expect(Conjur::Resource.all host: authz_host, account: account, kind: :chunky)
        .to eql(%w(foo bar))
    end
    
    it "passes search, limit, and offset params" do
      RestClient::Request.should_receive(:execute).with(
        method: :get,
        # Note that to_query sorts the keys
        url: "http://authz.example.com/the-account/resources?limit=5&offset=6&search=something",
        headers: {}
      ).and_return '["foo", "bar"]'
      Conjur::Resource.all(host: authz_host, account: account, search: 'something', limit:5, offset:6).should == %w(foo bar)
    end

    it "uses the given authz url" do
      RestClient::Request.should_receive(:execute).with(
        method: :get,
        url: "http://otherhost.example.com/the-account/resources",
        headers: {}
      ).and_return '["foo", "bar"]'

      Conjur::Resource.all host: 'http://otherhost.example.com', account: account
    end
  end
end
