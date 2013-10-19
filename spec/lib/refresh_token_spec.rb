require 'spec_helper'
describe Conjur::API do
  let(:timestamp) { Time.new(2013,1,1,1,1,1,0).utc }
  let(:expiration){ timestamp + 8 * 60 }
  let(:now){timestamp}
  let(:fresh_token){
    {
      "data" => "sandbox:user:test",
      "timestamp" => now
    }.tap { |t| 
      t["expiration"] = expiration if expiration
    }
  }
  let(:token){ fresh_token }
  subject{ Conjur::API.new_from_token token }
  before do
    Time.stub(:now).and_return now
  end
  
  
  def self.it_should_refresh
    it "should refresh the token" do
      Conjur::API.should_receive(:authenticate).and_return fresh_token
      subject.token
    end
  end
  def self.it_should_not_refresh
    it "should refresh the token" do
      Conjur::API.should_not_receive(:authenticate).and_return fresh_token
      subject.token
    end
  end
  
  context "when token is nil" do
    let(:token_ivar){ nil }
    it_should_refresh
  end
  
  context "when token is new" do
    let(:token_ivar){ fresh_token }
    it_should_not_refresh
  end
  
  context "when token is 6 minutes old" do
    let(:now) { timestamp + 6 * 60 }
    it_should_not_refresh
    context "with no expiration field" do
      let(:expiration){ nil }
      it_should_not_refresh
    end
  end
  
  context "when token is 7:01 minutes old" do
    let(:now){ timestamp + 1 + 7 * 60 }
    it_should_refresh
    context "with no expiration field" do
      let(:expiration){ nil }
      it_should_refresh
    end
  end
end