# frozen_string_literal: true

require 'spec_helper'

describe Conjur::BaseObject do

  it "returns custom string for #inspect" do
    id_str = 'foo:bar:baz'
    base_obj = Conjur::BaseObject.new(Conjur::Id.new(id_str), { username: 'foo' })
    expect(base_obj.inspect).to include("id='#{id_str}'")
    expect(base_obj.inspect).to include(Conjur::BaseObject.name)
  end
end
