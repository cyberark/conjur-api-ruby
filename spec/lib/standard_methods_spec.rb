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
    allow(subject).to receive(:fully_escape){|x|x}
    allow(RestClient::Resource).to receive(:new).with(host, credentials).and_return rest_resource
    allow(rest_resource).to receive(:[]).with('widgets').and_return subresource
    stub_const 'Conjur::Widget', widget_class
  end

  describe '#standard_create' do
    let(:id) { "some-id" }
    let(:options) {{ foo: 'bar', baz: 'xyzzy' }}

    let(:response) { double "response" }
    let(:widget) { double "widget" }

    before do
      allow(subresource).to receive(:post).with(options.merge(id: id)).and_return response
      allow(widget_class).to receive(:build_from_response).with(response, credentials).and_return widget
    end

    it "uses restclient to post data and creates an object of the response" do
      expect(subject.send(:standard_create, host, type, id, options)).to eq(widget)
    end
  end

  describe '#standard_list' do
    let(:attrs) {[{id: 'one', foo: 'bar'}, {id: 'two', foo: 'pub'}]}
    let(:options) {{ foo: 'bar', baz: 'xyzzy' }}
    let(:json) { attrs.to_json }

    before do
      allow(subresource).to receive(:get).with(options).and_return json
    end

    it "gets the list, then builds objects from json response" do
      expect(subject).to receive(:widget).with('one').and_return(one = double)
      expect(one).to receive(:attributes=).with(attrs[0].stringify_keys)
      expect(subject).to receive(:widget).with('two').and_return(two = double)
      expect(two).to receive(:attributes=).with(attrs[1].stringify_keys)

      expect(subject.send(:standard_list, host, type, options)).to eq([one, two])
    end
  end

  describe "#standard_show" do
    let(:id) { "some-id" }
    it "builds a path and returns indexed object" do
      allow(widget_class).to receive(:new).with(host, credentials).and_return(bound = double)
      allow(bound).to receive(:[]) { |x| "path: #{x}" }
      expect(subject.send(:standard_show, host, type, id)).to eq("path: widgets/some-id")
    end
  end
end
