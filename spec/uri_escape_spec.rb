require 'spec_helper'
require 'conjur/id'

describe 'url escaping' do
  it 'Id to path is escaped' do
    id = Conjur::Id.new('cucumber:variable:foo bar')
    expect(id.to_url_path).to eq('cucumber/variable/foo%20bar')
  end
end
