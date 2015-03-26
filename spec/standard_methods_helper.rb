require 'helpers/request_helpers'
shared_context api: :dummy do
  include RequestHelpers
  subject { api }
end

shared_examples_for 'standard_create with' do |type, id, options|
  it "calls through to standard_create" do
    expect(subject).to receive(:standard_create).with(
      core_host, type, id, options
    ).and_return :response
    expect(invoke).to eq(:response)
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
