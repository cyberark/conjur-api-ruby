require 'spec_helper'

require 'conjur/api'

describe Conjur::User do
  subject { Conjur::User.new(:host) }
  
  let(:user) { 'master' }
  let(:password) { 'master' }
  
  describe '#token_valid?' do
    it "raises KeyError when there's no authn key in the db" do
      stub_const 'Slosilo', Module.new
      Slosilo.stub(:[]).with(:authn).and_return nil
      expect { subject.token_valid? :whatever }.to raise_error(KeyError)
    end
  end
end
