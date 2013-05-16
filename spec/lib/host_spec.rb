require 'spec_helper'

describe Conjur::Host do
  let(:login) { 'the-login' }
  let(:api_key) { 'the-api-key' }
  let(:credentials) { { user: login, password: api_key } }
  let(:account) { 'test-account' }

  before { Conjur::Core::API.stub conjur_account: account }

  subject { Conjur::Host.new 'hostname', credentials }

  its(:resource) { should be }
end
