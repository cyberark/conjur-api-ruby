require 'spec_helper'
require 'standard_methods_helper'

describe Conjur::API, api: :dummy do
  describe '#create_user' do
    it_should_behave_like 'standard_create with', :user, nil, login: 'login', other: true do
      let(:invoke) { api.create_user 'login', other: true }
    end

    it "formats the CIDRs correctly" do
      cidrs = %w(192.0.2.0/24 198.51.100.0/24)
      expect do
        api.create_user 'login', cidr: cidrs.map(&IPAddr.method(:new))
      end.to call_standard_create_with :user, nil, login: 'login', cidr: cidrs
    end

    it "parses addresses given as strings" do
      expect do
        api.create_user 'login', cidr: %w(192.0.2.0/255.255.255.128)
      end.to call_standard_create_with :user, nil, login: 'login', cidr: %w(192.0.2.0/25)
    end

    it "raises ArgumentError on invalid CIDR" do
      expect do
        api.create_user 'login', cidr: %w(192.0.2.0/255.255.0.255)
      end.to raise_error ArgumentError

      expect do
        api.create_user 'login', cidr: %w(192.0.2.256/1)
      end.to raise_error ArgumentError
    end
  end

  describe 'user#update' do
    let(:userid) { "alice@wonderland" }
    it "PUTs to /users/:id?uidnumber=:uidnumber" do
      expect_request(
        method: :put,
        url: "#{core_host}/users/#{api.fully_escape(userid)}",
        headers: credentials[:headers],
        payload: { uidnumber: 12345 }
       )
      api.user(userid).update(uidnumber: 12345)
    end
    
  end

  describe "find_users" do

    let(:search_parameters) { {uidnumber: 12345} }
    let(:search_result)     { ["someuser"].to_json }
    
    it "GETs /users/search with appropriate options, and returns parsed JSON response" do
      expect_request(
        method: :get,  
        url: "#{core_host}/users/search?uidnumber=12345",
        headers: credentials[:headers]
      ).and_return search_result

      parsed = double()

      expect(JSON).to receive(:parse).with(search_result).and_return(parsed)

      expect(api.find_users(search_parameters)).to eq(parsed)
    end
  end

  describe '#user' do
    it_should_behave_like 'standard_show with', :user, :login do
      let(:invoke) { api.user :login }
    end
  end
end
