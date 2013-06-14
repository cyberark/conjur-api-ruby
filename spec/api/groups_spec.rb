require 'spec_helper'
require 'standard_methods_helper'

describe Conjur::API, api: :dummy do
  subject { api }

  describe '#groups' do
    it_should_behave_like 'standard_list with', :group, :options do
      let(:invoke) { subject.groups :options }
    end
  end

  describe '#create_group' do
    it_should_behave_like 'standard_create with', :group, :id, :options do
      let(:invoke) { subject.create_group :id, :options }
    end
  end

  describe '#group' do
    it_should_behave_like 'standard_show with', :group, :id do
      let(:invoke) { subject.group :id }
    end
  end
end
