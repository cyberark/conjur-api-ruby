require 'spec_helper'

require 'conjur/api'

describe Conjur::Resource do
  let(:user) { 'admin' }
  let(:api_key) { '^6feWZpr' }
  
  def conjur_api
    Conjur::API.new_from_key(user, api_key)
  end
  
  def self.it_creates_with code
    it "should create with status #{code}" do
      resource = conjur_api.resource("spec", identifier)
      resource.create
      resource.should exist
      conjur_api.resource("spec", identifier).kind.should == "spec"
      conjur_api.resource("spec", identifier).identifier.should == identifier
    end
  end

  def self.it_fails_with code
    it "should fail with status #{code}" do
      expect { conjur_api.resource("spec", identifier).create }.to raise_error { |error|
        error.should be_a(RestClient::Exception)
        error.http_code.should == code
      }
    end
  end

  let(:uuid) { "ddd1f59a-494d-48fb-b045-0374c4a6eef9" }
  
  context "identifier" do
    include Conjur::Escape
    let(:resource) { Conjur::Resource.new("#{Conjur::Authz::API.host}/#{kind}/#{path_escape identifier}") }
    [ [ "foo", "bar/baz" ], [ "f:o", "bar" ], [ "@f", "bar.baz" ], [ "@f", "bar baz" ], [ "@f", "bar?baz" ] ].each do |p|
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
  context "#create" do
    context "with uuid identifier" do
      use_vcr_cassette
      let(:identifier) { uuid }
      it_creates_with 204
      it "is findable" do
        conjur_api.resource("spec", identifier).create
        conjur_api.resource("spec", identifier).should exist
      end
    end
    context "with path-like identifier" do
      use_vcr_cassette
      let(:identifier) { [ uuid, "xxx" ].join("/") }
      it_creates_with 204
    end
    context "with un-encoded path-like identifier" do
      use_vcr_cassette
      let(:identifier) { [ uuid, "+?!!?+/xxx" ].join("/") }
      it_creates_with 204
    end
  end
end