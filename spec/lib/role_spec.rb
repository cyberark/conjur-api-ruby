require 'spec_helper'

describe Conjur::Role do
  let(:account) { "the-account" }
  let(:kind) { "test" }
  let(:role) { Conjur::API.new_from_token({ 'data' => 'the-login' }).role([ account, kind, id ].join(":")) }
  subject { role }

  describe ".new" do
    context "with plain id" do
      let(:id) { "foo" }
      its(:options) { should == {:headers=>{:authorization=>"Token token=\"eyJkYXRhIjoidGhlLWxvZ2luIn0=\""}, :username=>'the-login'} }
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
end
