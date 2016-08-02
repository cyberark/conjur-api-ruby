require 'spec_helper'

describe Possum::ApiKeyAuthenticator do
  subject(:authenticator) do
    conn = Faraday.new url: 'http://possum.test'
    Possum::ApiKeyAuthenticator.new conn, 'alice', 'api-key'
  end

  describe '#fetch_token' do
    it 'fetches a token' do
      stub_request(:post, 'http://possum.test/authn/alice/authenticate')
        .with(body: 'api-key')
        .to_return(body: 'the token')

      expect(authenticator.fetch_token).to eq 'dGhlIHRva2Vu'
    end
  end
end
