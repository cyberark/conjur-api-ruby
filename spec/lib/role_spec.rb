require 'spec_helper'
require 'standard_methods_helper'

describe Conjur::Role, api: :dummy do
  let(:account) { "the-account" }
  let(:kind) { "test" }
  let(:url) { "#{authz_host}/#{account}/roles/#{kind}/#{id}" }
  let(:role) { Conjur::Role.new url }
  subject { role }

  describe ".new" do
    context "with plain id" do
      let(:id) { "foo" }

      describe '#options' do
        subject { super().options }
        it {}
      end

      describe '#kind' do
        subject { super().kind }
        it { is_expected.to eq(kind) }
      end

      describe '#id' do
        subject { super().id }
        it { is_expected.to eq(id) }
      end
    end

    context "with more complex id" do
      let(:id) { "foo/bar" }

      describe '#kind' do
        subject { super().kind }
        it { is_expected.to eq(kind) }
      end

      describe '#id' do
        subject { super().id }
        it { is_expected.to eq(id) }
      end
    end
  end

  let(:id) { "role/id" }

  describe "#grant_to" do
    it "should take hash as the second argument and put it" do
      members = double "members request"
      expect(subject).to receive(:[]).with('?members&member=other').and_return(members)
      expect(members).to receive(:put).with admin_option: true
      subject.grant_to "other", admin_option: true
    end

    it "works without arguments" do
      members = double "members request"
      expect(subject).to receive(:[]).with('?members&member=other').and_return(members)
      expect(members).to receive(:put).with({})
      subject.grant_to "other"
    end

    it "converts an object to roleid" do
      members = double "members request"
      expect(subject).to receive(:[]).with('?members&member=other').and_return(members)
      expect(members).to receive(:put).with({})
      require 'ostruct'
      subject.grant_to OpenStruct.new(roleid: "other")
    end

    it "converts an Array to roleid" do
      members = double "members request"
      expect(subject).to receive(:[]).with('?members&member=other').and_return(members)
      expect(members).to receive(:put).with({})
      subject.grant_to %w(other)
    end
  end

  describe '#create' do
    it 'simply puts' do
      expect_request(
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
      expect_request(
        method: :get,
        url: role.url + "/?all=true",
        headers: {}
      ).and_return roles.to_json
      all = role.all
      expect(all[0].account).to eq('foo')
      expect(all[0].id).to eq('bar')
      expect(all[1].account).to eq('baz')
      expect(all[1].id).to eq('xyzzy')
    end

    it "handles 'count' parameter" do
      expect_request(
        method: :get,
        url: role.url + "/?all=true&count=true",
        headers: {}
      ).and_return({count: 12}.to_json)
      expect(role.all(count: true)).to eq(12)
    end

    describe "direct memberships" do
      it 'routes to ?memberships' do
        expect_request(
          method: :get,
          url: role.url + "/?memberships=true",
          headers: {}
        ).and_return("[]")
        role.all(recursive: false)
      end
    end
    
    describe "filter param" do
      it "applies #cast to the filter" do
        filter = %w(foo bar)
        filter.each{ |e| expect(subject).to receive(:cast).with(e, :roleid).and_return e }
        allow(RestClient::Request).to receive_messages execute: [].to_json
        role.all filter: filter
      end
      
      def self.it_passes_the_filter_as(query_string)
        it "calls ?all&#{query_string}" do
          expect_request(
            method: :get,
            url: role.url + "/?all=true&#{query_string}",
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
      expect(role).to receive(:all).with(filter: 'the filter').and_return ['an id']
      expect(role.member_of?('the filter')).to be_truthy
      expect(role).to receive(:all).with(filter: 'the filter').and_return []
      expect(role.member_of?('the filter')).to be_falsey
    end
    
    it "accepts a Role" do
      other = double('Role', roleid: 'foo')
      expect(role).to receive(:all).with(filter: other.roleid).and_return []
      role.member_of?(other)
    end
  end

  describe '#revoke_from' do
    it 'deletes member' do
      expect_request(
        method: :delete,
        url: role.url + "/?members&member=the-member",
        headers: {}
      )
      role.revoke_from 'the-member'
    end
  end

  describe '#permitted?' do
    before do
      allow_request(
        method: :get,
        url: role.url + "/?check&resource_id=chunky:bacon&privilege=fry",
        headers: {}
      ) { result }
    end

    context "when get ?check is successful" do
      let(:result) { :ok }
      it "returns true" do
        expect(role.permitted?('chunky:bacon', 'fry')).to be_truthy
      end
    end

    context "when get ?check not found" do
      let(:result) { raise RestClient::ResourceNotFound, 'foo' }
      it "returns false" do
        expect(role.permitted?('chunky:bacon', 'fry')).to be_falsey
      end
    end
  end

  describe '#members' do
    it "can count the grants" do
      expect_request(
        method: :get,
        url: role.url + "/?count=true&members=true"
      ).and_return({count: 12}.to_json)

      expect(subject.members(count: true)).to eq(12)
    end

    it "gets ?members and turns each into RoleGrant" do
      grants = %w(foo bar)
      expect_request(
        method: :get,
        url: role.url + "/?members=true"
      ).and_return grants.to_json
      grants.each do |g|
        expect(Conjur::RoleGrant).to receive(:parse_from_json).with(g, anything).and_return g
      end

      expect(subject.members).to eq(grants)
    end
  end
end
