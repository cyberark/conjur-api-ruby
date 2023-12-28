require 'spec_helper'
require 'conjur/id'
require 'conjur/api/router'

describe 'url escaping' do
  it 'Id to path is escaped' do
    id = Conjur::Id.new('cucumber:variable:one two/three')
    expect(id.to_url_path).to eq('cucumber/variable/one%20two%2Fthree')
  end

  it 'Resources path is escaped' do
    request = Conjur::API::Router.resources(nil, 'cucumber/two', 'extended variable', {})
    expect(request.url).to eq('http://localhost:5000/resources/cucumber%2Ftwo/extended%20variable/')
  end

  it 'Resource path is escaped' do
    resource = Conjur::Id.new('cucumber:variable:one two/three')
    request = Conjur::API::Router.resources_resource(nil, resource)
    expect(request.url).to eq('http://localhost:5000/resources/cucumber/variable/one%20two%2Fthree')
  end
end
