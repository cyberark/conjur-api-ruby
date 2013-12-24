require 'spec_helper'

describe RestClient::Resource do
  shared_examples_for "URL path parsing" do
    let(:resource) { RestClient::Resource.new(base_url)[path] }
    
    shared_examples_for "extracts the expected identifier" do
      include Conjur::HasId
      before {
        Conjur::Core::API.stub(:host).and_return base_url
      }
      specify {
        resource.path_components.should == path_components
        id.should == path_components[1..-1].join('/')
      }
    end
    
    it_should_behave_like "extracts the expected identifier" do
      let(:path) { "hosts/foo" }
      let(:path_components) { [ "hosts", "foo" ] }
    end
    it_should_behave_like "extracts the expected identifier" do
      let(:path) { "hosts/foo/bar" }
      let(:path_components) { [ "hosts", "foo", "bar" ] }
    end
    it_should_behave_like "extracts the expected identifier" do
      let(:path) { "hosts/foo%2Fbar" }
      let(:path_components) { [ "hosts", "foo/bar" ] }
    end
  end

  context "with base URL http://example.com" do
    let(:base_url) { "http://example.com" }
    it_should_behave_like "URL path parsing"
  end
  context "with base URL http://example.com/api" do
    let(:base_url) { "http://example.com/api" }
    it_should_behave_like "URL path parsing"
  end
  context "with base URL http://example.com/api/" do
    let(:base_url) { "http://example.com/api/" }
    it_should_behave_like "URL path parsing"
  end
end