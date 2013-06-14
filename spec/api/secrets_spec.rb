require 'spec_helper'
require 'standard_methods_helper'

describe Conjur::API, api: :dummy do
  describe '#create_secret' do
    it_should_behave_like 'standard_create with', :secret, nil, value: 'val' do
      let(:invoke) { api.create_secret 'val' }
    end
  end

  describe '#secret' do
    it_should_behave_like 'standard_show with', :secret, :id do
      let(:invoke) { api.secret :id }
    end
  end
end
