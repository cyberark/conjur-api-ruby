require 'spec_helper'

describe Conjur::API, api: :dummy do
  describe '#role_name_from_username' do
    subject { api }
    before {
      allow(api).to receive(:username) { username }
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

          describe '#role_name_from_username' do
            subject { super().role_name_from_username }
            it { is_expected.to eq(p[1]) }
          end
        end
      end
    end
  end
end
