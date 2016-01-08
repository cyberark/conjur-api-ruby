require 'spec_helper'
require 'cas_rest_client'
require 'helpers/request_helpers'

describe Conjur::API do
  include RequestHelpers

  let(:host) { 'http://authn.example.com' }
  let(:user) { 'kmitnick' }
  let(:password) { 'sikret' }

  before do
    allow(Conjur::Authn::API).to receive_messages host: host
  end

  describe "::login" do
    it "gets /users/login" do
      expect_request(
        method: :get, url: "http://authn.example.com/users/login", 
        user: user,
        password: password, 
        headers: {}
      ).and_return(response = double)
      expect(Conjur::API::login(user, password)).to eq(response)
    end
  end

  describe "::login_cas" do
    let(:response) { "response body" }
    let(:cas_uri) { 'http://cas.example.com' }

    it "uses CasRestClient to authenticate" do
      stub_const 'CasRestClient', MockCasRestClient.new(double("response", body: response))
      expect(Conjur::API.login_cas(user, password, cas_uri)).to eq(response)
      expect(CasRestClient.options).to eq({
        username: user,
        password: password,
        uri: "http://cas.example.com/v1/tickets",
        use_cookies: false
      })
      expect(CasRestClient.url).to eq("http://authn.example.com/users/login")
    end
  end

  describe "::authenticate" do
    it "posts the password and dejsons the result" do
      expect_request(
        method: :post, url: "http://authn.example.com/users/#{user}/authenticate",
        payload: password, headers: { content_type: 'text/plain' }
      ).and_return '{ "response": "foo"}'
      expect(Conjur::API.authenticate(user, password)).to eq({ 'response' => 'foo' })
    end
  end
  
  describe "::update_password" do
    it "logs in and puts the new password" do
      expect_request(
        method: :put, 
        url: "http://authn.example.com/users/password",
        user: user,
        password: password,
        payload: 'new-password', 
        headers: {  }
      ).and_return :response
      expect(Conjur::API.update_password(user, password, 'new-password')).to eq(:response)
    end
  end

  describe '::rotate_api_key' do
    it 'puts with basic auth' do
      expect_request(
          method: :put,
          url: 'http://authn.example.com/users/api_key',
          user: user,
          password: password,
          headers: { }
      ).and_return double('response', body: 'new api key')
      expect(Conjur::API.rotate_api_key user, password).to eq('new api key')
    end
  end
end
