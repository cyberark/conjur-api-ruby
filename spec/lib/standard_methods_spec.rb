require 'spec_helper'

describe Conjur::StandardMethods do
  let(:credentials) { "whatever" }
  subject { double("class", credentials: credentials, log: nil) }
  let(:host) { 'http://example.com' }
  let(:type) { :widget }

  let(:rest_resource) { double "rest base resource" }
  let(:subresource) { double "rest subresource" }

  let(:widget_class) { double "widget class" }

  before do
    subject.extend Conjur::StandardMethods
    subject.stub(:fully_escape){|x|x}
    RestClient::Resource.stub(:new).with(host, credentials).and_return rest_resource
    rest_resource.stub(:[]).with('widgets').and_return subresource
    stub_const 'Conjur::Widget', widget_class
  end

  describe '#standard_create' do
    let(:id) { "some-id" }
    let(:options) {{ foo: 'bar', baz: 'xyzzy' }}

    let(:response) { double "response" }
    let(:widget) { double "widget" }

    before do
      subresource.stub(:post).with(options.merge(id: id)).and_return response
      widget_class.stub(:build_from_response).with(response, credentials).and_return widget
    end

    it "uses restclient to post data and creates an object of the response" do
      subject.send(:standard_create, host, type, id, options).should == widget
    end
  end

  describe '#standard_list' do
    let(:attrs) {
        [
          { id: 'one', 
            resource_id: 'account1:kind1:one',
            foo: 'bar'}, 
          { id: 'two', 
            resource_id: 'account2:kind2:two',
            foo: 'bar'}
        ]}
    let(:options) {{ foo: 'bar', baz: 'xyzzy' }}
    let(:json) { attrs.to_json }

    before do
      subresource.stub(:get).with(options).and_return json
    end

    it "gets the list, then builds objects from json response" do
      subject.send(:standard_list, host, type, options).should == 
        [attrs[0][:resource_id], attrs[1][:resource_id]]
    end
  end

  describe "#standard_show" do
    let(:id) { "some-id" }
    it "builds a path and returns indexed object" do
      widget_class.stub(:new).with(host, credentials).and_return(bound = double)
      bound.stub(:[]) { |x| "path: #{x}" }
      subject.send(:standard_show, host, type, id).should == "path: widgets/some-id"
    end
  end
end
