require 'spec_helper'
require 'standard_methods_helper'

describe Conjur::API, api: :dummy do
  describe '#create_user' do
    it_should_behave_like 'standard_create with', :user, nil, login: 'login', other: true do
      let(:invoke) { api.create_user 'login', other: true }
    end
  end

  describe '#user' do
    it_should_behave_like 'standard_show with', :user, :login do
      let(:invoke) { api.user :login }
    end
  end
end
