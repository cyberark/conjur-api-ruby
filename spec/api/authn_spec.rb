require 'spec_helper'
require 'cas_rest_client'

describe Conjur::API do
  let(:host) { 'http://authn.example.com' }
  let(:user) { 'kmitnick' }
  let(:password) { 'sikret' }

  before do
    Conjur::Authn::API.stub host: host
  end

  describe "::login" do
    it "gets /users/login" do
      RestClient::Request.should_receive(:execute).with(
        method: :get, url: "http://authn.example.com/users/login", 
        user: user,
        password: password, 
        headers: {}
      ).and_return(response = double)
      Conjur::API::login(user, password).should == response
    end
  end

  describe "::login_cas" do
    let(:response) { "response body" }
    let(:cas_uri) { 'http://cas.example.com' }

    it "uses CasRestClient to authenticate" do
      stub_const 'CasRestClient', MockCasRestClient.new(double("response", body: response))
      Conjur::API.login_cas(user, password, cas_uri).should == response
      CasRestClient.options.should == {
        username: user,
        password: password,
        uri: "http://cas.example.com/v1/tickets",
        use_cookies: false
      }
      CasRestClient.url.should == "http://authn.example.com/users/login"
    end
  end

  describe "::authenticate" do
    it "posts the password and dejsons the result" do
      RestClient::Request.should_receive(:execute).with(
        method: :post, url: "http://authn.example.com/users/#{user}/authenticate",
        payload: password, headers: { content_type: 'text/plain' }
      ).and_return '{ "response": "foo"}'
      Conjur::API.authenticate(user, password).should == { 'response' => 'foo' }
    end
  end
  
  describe "::update_password" do
    it "logs in and puts the new password" do
      RestClient::Request.should_receive(:execute).with(
        method: :put, 
        url: "http://authn.example.com/users/password",
        user: user,
        password: password,
        payload: 'new-password', 
        headers: {  }
      ).and_return :response
      Conjur::API.update_password(user, password, 'new-password').should == :response
    end
  end
end
