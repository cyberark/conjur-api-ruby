require 'spec_helper'
require 'standard_methods_helper'

describe Conjur::API, api: :dummy do
  describe '#create_variable' do
    let(:invoke) { api.create_variable :type, :kind, other: true }
    it_should_behave_like 'standard_create with', :variable, nil, mime_type: :type, kind: :kind, other: true
  end

  describe '#variable' do
    let(:invoke) { api.variable :id }
    it_should_behave_like 'standard_show with', :variable, :id
  end
end
