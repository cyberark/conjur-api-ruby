require 'spec_helper'

describe Conjur::Resource do
  let(:account) { "the-account" }
  let(:uuid) { "ddd1f59a-494d-48fb-b045-0374c4a6eef9" }
  
  context "identifier" do
    include Conjur::Escape
    let(:resource) { Conjur::Resource.new("#{Conjur::Authz::API.host}/#{account}/resources/#{kind}/#{path_escape identifier}") }
    
    context "Object with an #id" do
      let(:kind) { "host" }
      let(:identifier) do
        Conjur::Host.new("#{Conjur::Core::API.host}/hosts/foobar", {})
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
end