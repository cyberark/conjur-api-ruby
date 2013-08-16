require 'spec_helper'

describe Conjur::Role, api: :dummy do
  let(:account) { "the-account" }
  let(:kind) { "test" }
  let(:url) { "#{authz_host}/#{account}/roles/#{kind}/#{id}" }
  let(:role) { Conjur::Role.new url }
  subject { role }

  describe ".new" do
    context "with plain id" do
      let(:id) { "foo" }
      its(:options) {}
      its(:kind) { should == kind }
      its(:id) { should == id }
    end

    context "with more complex id" do
      let(:id) { "foo/bar" }
      its(:kind) { should == kind }
      its(:id) { should == id }
    end
  end

  let(:id) { "role/id" }

  describe "#grant_to" do
    it "should take hash as the second argument and put it" do
      members = double "members request"
      subject.should_receive(:[]).with('?members&member=other').and_return(members)
      members.should_receive(:put).with admin_option: true
      subject.grant_to "other", admin_option: true
    end

    it "works without arguments" do
      members = double "members request"
      subject.should_receive(:[]).with('?members&member=other').and_return(members)
      members.should_receive(:put).with nil
      subject.grant_to "other"
    end

    context deprecated: 'v3' do # remove in 3.0
      it "should also accept the deprecated argument format with extra options" do
        members = double "members request"
        subject.should_receive(:[]).with('?members&member=other').and_return(members)
        members.should_receive(:put).with admin_option: true, foo: 'bar'
        subject.grant_to "other", true, foo: 'bar'
      end

      it "should also accept the deprecated argument format without extra options" do
        members = double "members request"
        subject.should_receive(:[]).with('?members&member=other').and_return(members)
        members.should_receive(:put).with admin_option: true, foo: 'bar'
        subject.grant_to "other", true, foo: 'bar'
      end
    end
  end

  describe '#create' do
    it 'simply puts' do
      RestClient::Request.should_receive(:execute).with(
        method: :put,
        url: url,
        payload: {},
        headers: {}
      )
      role.create
    end
  end

  describe '#all' do
    it 'returns roles for ids got from ?all' do
      roles = ['foo:k:bar', 'baz:k:xyzzy'] 
      RestClient::Request.should_receive(:execute).with(
        method: :get,
        url: role.url + "/?all",
        headers: {}
      ).and_return roles.to_json
      all = role.all
      all[0].account.should == 'foo'
      all[0].id.should == 'bar'
      all[1].account.should == 'baz'
      all[1].id.should == 'xyzzy'
    end
  end

  describe '#revoke_from' do
    it 'deletes member' do
      RestClient::Request.should_receive(:execute).with(
        method: :delete,
        url: role.url + "/?members&member=the-member",
        headers: {}
      )
      role.revoke_from 'the-member'
    end
  end

  describe '#permitted?' do
    before do
      RestClient::Request.stub(:execute).with(
        method: :get,
        url: role.url + "/?check&resource_id=chunky:bacon&privilege=fry",
        headers: {}
      ) { result }
    end

    context "when get ?check is successful" do
      let(:result) { :ok }
      it "returns true" do
        role.permitted?('chunky', 'bacon', 'fry').should be_true
      end
    end

    context "when get ?check not found" do
      let(:result) { raise RestClient::ResourceNotFound, 'foo' }
      it "returns false" do
        role.permitted?('chunky', 'bacon', 'fry').should be_false
      end
    end
  end

  describe '#members' do
    it "gets ?members and turns each into RoleGrant" do
      grants = %w(foo bar)
      RestClient::Request.should_receive(:execute).with(
        method: :get,
        url: role.url + "/?members",
        headers: {}
      ).and_return grants.to_json
      grants.each do |g|
        Conjur::RoleGrant.should_receive(:parse_from_json).with(g, {}).and_return g
      end

      subject.members.should == grants
    end
  end
end
