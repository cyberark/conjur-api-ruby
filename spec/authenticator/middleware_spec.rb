require 'spec_helper'

describe Possum::Authenticator::Middleware do
  let(:authenticator) { Possum::Authenticator.new.tap { |a| a.token = 'the token' } }
  let(:app) { double 'app' }
  subject(:middleware) { Possum::Authenticator::Middleware.new app, authenticator }

  describe '#call' do
    it "attaches authentication header" do
      expect(app).to receive(:call).with request_headers: {
        'Authorization' => 'Token token="the token"'
      }
      middleware.call request_headers: {}
    end
  end
end
