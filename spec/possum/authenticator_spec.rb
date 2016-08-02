require 'spec_helper'

describe Possum::Authenticator do
  subject(:authenticator) { Possum::Authenticator.new }

  describe '#token' do
    it 'returns an encoded token' do
      authenticator.token = 'the token'
      expect(authenticator.token).to eq 'the token'
    end

    it 'tries to fetch a token if there is none' do
      allow(authenticator).to receive(:fetch_token).and_return 'the token'
      expect(authenticator.token).to eq 'the token'
    end

    it 'tries to fetch a token if expired' do
      authenticator.token = 'the token'
      allow(authenticator).to receive_messages \
          token_expired?: true,
          fetch_token: 'new token'
      expect(authenticator.token).to eq 'new token'
    end

    it 'gives the old token if fetching failed' do
      skip 'decide if it should do that'
    end
  end
end
