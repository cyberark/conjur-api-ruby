require 'spec_helper'

describe Conjur::User do
  context "#new" do
    let(:login) { 'the-login' }
    let(:url) { "https://example.com/users/#{login}" }
    let(:api_key) { 'the-api-key' }
    let(:credentials) { { user: login, password: api_key } }
    let(:user) { Conjur::User.new(url, credentials)}
    describe "attributes" do
      subject { user }

      describe '#id' do
        subject { super().id }
        it { is_expected.to eq(login) }
      end

      describe '#login' do
        subject { super().login }
        it { is_expected.to eq(login) }
      end

      describe '#resource_id' do
        subject { super().resource_id }
        it { is_expected.to eq(login) }
      end

      describe '#resource_kind' do
        subject { super().resource_kind }
        it { is_expected.to eq("user") }
      end

      describe '#options' do
        subject { super().options }
        it { is_expected.to match(hash_including credentials) }
      end

      describe '#roleid' do
        it "gets account name from server info" do
          allow(Conjur::Core::API).to receive_messages conjur_account: 'test-account'
          expect(subject.roleid).to eq "test-account:user:#{login}"
        end
      end
    end
    it "connects to a Resource" do
      require 'conjur/resource'
      expect(Conjur::Core::API).to receive(:conjur_account).and_return 'ci'
      expect(Conjur::Resource).to receive(:new).with(
        Conjur::Authz::API.host, hash_including(credentials)
      ).and_return resource = double(:resource)
      expect(resource).to receive(:[]).with("ci/resources/user/the-login")
      
      user.resource
    end
    it "connects to a Role" do
      require 'conjur/role'
      expect(Conjur::Core::API).to receive(:conjur_account).and_return 'ci'
      expect(Conjur::Role).to receive(:new).with(
        Conjur::Authz::API.host, hash_including(credentials)
      ).and_return role = double(:role)
      expect(role).to receive(:[]).with("ci/roles/user/the-login")
      
      user.role
    end
  end
end
