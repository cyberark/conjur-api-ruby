require 'spec_helper'

describe Possum do
  before do
    stub_request(:get, 'http://possum.test/authn/login')
      .with(basic_auth: %w(alice secret))
      .to_return(body: 'api-key')

    stub_request(:post, 'http://possum.test/authn/alice/authenticate')
      .with(body: 'api-key')
      .to_return(body: 'the token')

    stub_request(:get, 'http://possum.test/resources/test/chunky/bacon')
      .with(headers: { 'Authorization' => 'Token token="dGhlIHRva2Vu"' })
      .to_return(body: { kind: 'chunky', id: 'bacon' }.to_json)
  end

  it 'can be created, authenticated and used' do
    possum = Possum::Client.new url: 'http://possum.test'
    possum.login 'alice', 'secret'
    expect(possum.get '/resources/test/chunky/bacon').to eq 'kind' => 'chunky', 'id' => 'bacon'
  end
end
