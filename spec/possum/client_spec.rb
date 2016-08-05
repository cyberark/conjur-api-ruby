require 'spec_helper'

describe Possum::Client do
  subject(:client) do
    Possum::Client.new url: 'http://possum.test'
  end

  describe '#login' do
    it "fetches the API key" do
      stub_request(:get, 'http://possum.test/authn/my-account/login')
        .with(basic_auth: %w(alice secret))
        .to_return(body: 'api-key')

      client.login 'my-account', 'alice', 'secret'
      expect(client.api_key).to eq 'api-key'
    end

    it "errors out on bad password" do
      stub_request(:get, 'http://possum.test/authn/my-account/login')
        .to_return(status: 401)

      expect { client.login 'my-account', 'alice', 'secret' }.to raise_error Possum::CredentialError
    end

    it "errors out on unexpected response" do
      stub_request(:get, 'http://possum.test/authn/my-account/login')
        .to_return(status: 418, body: "I'm a teapot")

      expect { client.login 'my-account', 'alice', 'secret' }.to raise_error Possum::UnexpectedResponseError
    end
  end

  describe '#get' do
    it "accepts query parameters" do
      stub_request(:get, 'http://possum.test/resources/my-account/test/chunky/bacon?check&privilege=fry')
        .to_return(
          body: ""
        )

        expect(client.get '/resources/my-account/test/chunky/bacon',
          check: nil,
          privilege: 'fry'
        ).to be_empty
    end
  end

  describe '#put' do
    it "accepts PUT body" do
      stub_request(:put, 'http://possum.test/my-account/password')
        .with(body: 'new password')
        .to_return(status: 204)

        expect { client.put '/my-account/password', 'new password' }.to_not raise_error
    end
  end

  describe '#post' do
    it "accepts POST body" do
      secret = """
        NEW SECRET VALUE
        !!!!
      """
      stub_request(:post, 'http://possum.test/secrets/my-account/test/chunky/bacon')
        .with(body: secret)
        .to_return(status: 201)

        expect { client.post '/secrets/my-account/test/chunky/bacon', secret }.to_not raise_error
    end
  end
end
