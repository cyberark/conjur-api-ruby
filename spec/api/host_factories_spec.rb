# frozen_string_literal: true

require 'spec_helper'
require 'conjur/api/host_factories'

describe "Conjur::API.host_factory_create_host", api: :dummy do
  it "returns a Host instance correctly on v4" do
    token = "host factory token"
    id = "test-host"

    allow(Conjur::API).to receive(:url_for)
      .with(:host_factory_create_host, token).and_return(
        resource = instance_double(RestClient::Resource, "hosts")
      )

    allow(resource).to receive(:post).with({id: id}).and_return(
      instance_double(RestClient::Response, "host response", body: '
        {
          "id": "test-host",
          "userid": "hosts",
          "created_at": "2015-11-13T22:57:14Z",
          "ownerid": "cucumber:group:ops",
          "roleid": "cucumber:host:test-host",
          "resource_identifier": "cucumber:host:test-host",
          "api_key": "14x82x72syhnnd1h8jj24zj1kqd2j09sjy3tddwxc35cmy5nx33ph7"
        }
      ')
    )

    host = Conjur::API.host_factory_create_host token, id

    expect(host).to be_a Conjur::Host
  end
end
