#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'spec_helper'

describe Conjur::API, api: :dummy do
  let(:pubkeys_url){ "http://pubkeys.example.com/api/pubkeys" }
  def pubkeys_url_for *path
    [pubkeys_url, path.map{|p| CGI.escape(p)} ].join("/")  
  end
  
  before do
    Conjur::API.stub(pubkeys_asset_host: pubkeys_url)
  end
  
  describe "#public_keys" do
    it "GETs /:username" do
      RestClient::Request.should_receive(:execute).with(
        url: pubkeys_url_for("bob"),
        method: :get,
        headers: {},
        user: credentials,
        password: nil
      ).and_return "key key key"
      expect(api.public_keys("bob")).to eq("key key key")
    end
  end
  
  describe "#add_public_key" do
    it "POSTs /:username with the data" do
      RestClient::Request.should_receive(:execute).with(
        url: pubkeys_url_for("bob"),
        method: :post,
        headers: {},
        payload: "key data",
        user: credentials,
        password: nil
      )
      api.add_public_key("bob", "key data")
    end
  end
  
  describe "#delete_public_key" do
    it "DELETEs /:username/:keyname" do
      RestClient::Request.should_receive(:execute).with(
        url: pubkeys_url_for("bob", "bob-key"),
        method: :delete,
        headers: {},
        user: credentials,
        password: nil
      )
      api.delete_public_key("bob", "bob-key")
    end
  end
end