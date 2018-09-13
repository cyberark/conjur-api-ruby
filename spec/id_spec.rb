# frozen_string_literal: true

require 'spec_helper'

describe Conjur::Id do
  it 'requires the id to be fully qualified' do
    expect { Conjur::Id.new 'foo:bar' }.to raise_error ArgumentError
  end

  it 'can be constructed from a string' do
    id = Conjur::Id.new 'foo:bar:baz'
    expect(id).to be
    {
      account: 'foo',
      kind: 'bar',
      identifier: 'baz'
    }.each { |k, v| expect(id.send(k)).to eq v }
  end

  it 'can be constructed from an array' do
    id = Conjur::Id.new %w(foo bar baz)
    expect(id).to be
    {
      account: 'foo',
      kind: 'bar',
      identifier: 'baz'
    }.each { |k, v| expect(id.send(k)).to eq v }
  end
end
