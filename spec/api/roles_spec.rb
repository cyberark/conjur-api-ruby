require 'spec_helper'

describe Conjur::API, api: :dummy do
  describe '#role_name_from_username' do
    subject { api }
    before {
      api.stub(:username) { username }
    }
    context "username is" do
      [ 
        [ 'the-user', 'user:the-user' ], 
        [ 'host/the-host', 'host:the-host' ],
        [ 'host/a/quite/long/host/name', 'host:a/quite/long/host/name' ],
        [ 'newkind/host/name', 'newkind:host/name' ],
      ].each do |p|
        context "'#{p[0]}'" do
          let(:username) { p[0] }
          its("role_name_from_username") { should == p[1] }
        end
      end
    end
  end
end
