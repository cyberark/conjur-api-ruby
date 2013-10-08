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
      members.should_receive(:put).with({})
      subject.grant_to "other"
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
    
    
    describe "filter param" do
      def self.it_passes_the_filter_as(query_string)
        it "calls ?all&#{query_string}" do
          RestClient::Request.should_receive(:execute).with(
            method: :get,
            url: role.url + "/?all&#{query_string}",
            headers:{}
          ).and_return([].to_json)
          role.all filter: filter
        end
      end
      context "when a string" do
        let(:filter){ 'string' }
        it_passes_the_filter_as ['string'].to_query('filter')
      end

      context "when an array" do
        let(:filter){ ['foo', 'bar'] }
        it_passes_the_filter_as ['foo', 'bar'].to_query('filter')
      end
    end

  end
  
  describe '#member_of?' do
    it 'calls #all with :filter=>id and returns true if the result is non-empty' do
      role.should_receive(:all).with(filter: 'the filter').and_return ['an id']
      role.member_of?('the filter').should be_true
      role.should_receive(:all).with(filter: 'the filter').and_return []
      role.member_of?('the filter').should be_false
    end
    
    it "accepts a Role" do
      other = double('Role', roleid: 'foo')
      role.should_receive(:all).with(filter: other.roleid).and_return []
      role.member_of?(other)
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
        role.permitted?('chunky:bacon', 'fry').should be_true
      end
    end

    context "when get ?check not found" do
      let(:result) { raise RestClient::ResourceNotFound, 'foo' }
      it "returns false" do
        role.permitted?('chunky:bacon', 'fry').should be_false
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
