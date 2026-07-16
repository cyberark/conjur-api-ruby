# frozen_string_literal: true

require 'spec_helper'
require 'conjur/api/server_version'

describe "Conjur::API#server_version", api: :dummy do
  let(:info_resource) { instance_double(RestClient::Resource, "info resource") }
  let(:root_resource) { instance_double(RestClient::Resource, "root resource") }

  before do
    allow(Conjur::API::Router).to receive(:server_info).and_return(info_resource)
    allow(Conjur::API::Router).to receive(:server_root).and_return(root_resource)
  end

  it "returns the possum service version from the /info endpoint" do
    body = {
      "services" => { "possum" => { "version" => "1.21.1.1-25" } }
    }.to_json
    allow(info_resource).to receive(:get).and_return(
      instance_double(RestClient::Response, "info response", body: body)
    )

    expect(api.server_version).to eq("1.21.1.1-25")
  end

  it "falls back to root when /info responds 404 (OSS)" do
    response = instance_double(RestClient::Response, "404 response", body: '', code: 404)
    allow(info_resource).to receive(:get).and_raise(RestClient::NotFound.new(response))

    root_body = { "version" => "1.20.0" }.to_json
    allow(root_resource).to receive(:get).and_return(
      instance_double(RestClient::Response, "root response", body: root_body, headers: { content_type: 'application/json' })
    )

    expect(api.server_version).to eq("1.20.0")
  end

  it "falls back to root when /info responds 500 (not just 404/401)" do
    response = instance_double(RestClient::Response, "500 response", body: '', code: 500)
    allow(info_resource).to receive(:get).and_raise(RestClient::InternalServerError.new(response))

    root_body = { "version" => "1.20.0" }.to_json
    allow(root_resource).to receive(:get).and_return(
      instance_double(RestClient::Response, "root response", body: root_body, headers: { content_type: 'application/json' })
    )

    expect(api.server_version).to eq("1.20.0")
  end

  it "parses a JSON root response even when Content-Type includes a charset" do
    allow(info_resource).to receive(:get).and_raise(RestClient::NotFound.new(instance_double(RestClient::Response, body: '', code: 404)))

    root_body = { "version" => "1.20.0" }.to_json
    allow(root_resource).to receive(:get).and_return(
      instance_double(RestClient::Response, "root response", body: root_body, headers: { content_type: 'application/json; charset=utf-8' })
    )

    expect(api.server_version).to eq("1.20.0")
  end

  it "parses an HTML root response when Content-Type is not JSON" do
    allow(info_resource).to receive(:get).and_raise(RestClient::NotFound.new(instance_double(RestClient::Response, body: '', code: 404)))

    root_body = "<html><body><dd>Version 1.19.0-359</dd></body></html>"
    allow(root_resource).to receive(:get).and_return(
      instance_double(RestClient::Response, "root response", body: root_body, headers: { content_type: 'text/html' })
    )

    expect(api.server_version).to eq("1.19.0-359")
  end

  it "parses an HTML root response with the Version label and value in separate tags" do
    allow(info_resource).to receive(:get).and_raise(RestClient::NotFound.new(instance_double(RestClient::Response, body: '', code: 404)))

    root_body = "<html><body><dt>Version</dt><dd>1.28.0-1443</dd></body></html>"
    allow(root_resource).to receive(:get).and_return(
      instance_double(RestClient::Response, "root response", body: root_body, headers: { content_type: 'text/html' })
    )

    expect(api.server_version).to eq("1.28.0-1443")
  end

  it "raises FeatureNotAvailable when neither endpoint yields a version" do
    allow(info_resource).to receive(:get).and_raise(RestClient::NotFound.new(instance_double(RestClient::Response, body: '', code: 404)))
    allow(root_resource).to receive(:get).and_raise(RestClient::InternalServerError.new(instance_double(RestClient::Response, body: '', code: 500)))

    expect { api.server_version }.to raise_error(Conjur::FeatureNotAvailable, /Unable to determine Conjur server version/)
  end

  it "memoizes a successful lookup" do
    body = { "services" => { "possum" => { "version" => "1.21.1" } } }.to_json
    allow(info_resource).to receive(:get).and_return(
      instance_double(RestClient::Response, "info response", body: body)
    )

    api.server_version
    api.server_version

    expect(info_resource).to have_received(:get).once
  end

  it "does not memoize a failed lookup, retrying on the next call" do
    allow(info_resource).to receive(:get).and_raise(RestClient::NotFound.new(instance_double(RestClient::Response, body: '', code: 404)))
    allow(root_resource).to receive(:get).and_raise(RestClient::InternalServerError.new(instance_double(RestClient::Response, body: '', code: 500)))

    expect { api.server_version }.to raise_error(Conjur::FeatureNotAvailable)
    expect { api.server_version }.to raise_error(Conjur::FeatureNotAvailable)

    expect(info_resource).to have_received(:get).twice
  end
end
