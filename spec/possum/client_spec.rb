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
end
