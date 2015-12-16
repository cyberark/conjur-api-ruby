require 'helpers/request_helpers'
shared_context api: :dummy do
  include RequestHelpers

  RSpec::Matchers.define :call_standard_create_with do |type, id, options|
    match do |block|
      expect(subject).to receive(:standard_create).with(
        core_host, type, id, options
      ).and_return :response
      expect(block[]).to eq(:response)
    end

    supports_block_expectations
  end

  subject { api }
end

shared_examples_for 'standard_create with' do |type, id, options|
  it "calls through to standard_create" do
    expect { invoke }.to call_standard_create_with type, id, options
  end
end

shared_examples_for 'standard_list with' do |type, options|
  it "calls through to standard_list" do
    expect(subject).to receive(:standard_list).with(
      core_host, type, options
    ).and_return :response
    expect(invoke).to eq(:response)
  end
end

shared_examples_for 'standard_show with' do |type, id|
  it "calls through to standard_show" do
    expect(subject).to receive(:standard_show).with(
      core_host, type, id
    ).and_return :response
    expect(invoke).to eq(:response)
  end
end
