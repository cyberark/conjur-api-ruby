require 'spec_helper'

describe RestClient::Resource do
  context "URL path parsing" do
    let(:resource) { RestClient::Resource.new "http://test.host/#{path}" }
    
    shared_examples_for "extracts the expected identifier" do
      include Conjur::HasId
      specify {
        resource.path_components.should == path_components
        id.should == path_components[2..-1].join('/')
      }
    end
    
    it_should_behave_like "extracts the expected identifier" do
      let(:path) { "hosts/foo" }
      let(:path_components) { [ "", "hosts", "foo" ] }
    end
    it_should_behave_like "extracts the expected identifier" do
      let(:path) { "hosts/foo/bar" }
      let(:path_components) { [ "", "hosts", "foo", "bar" ] }
    end
    it_should_behave_like "extracts the expected identifier" do
      let(:path) { "hosts/foo%2Fbar" }
      let(:path_components) { [ "", "hosts", "foo/bar" ] }
    end
  end
end