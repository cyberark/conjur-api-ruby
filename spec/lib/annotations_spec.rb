require 'spec_helper'

describe Conjur::Annotations do
  let(:identifier){ 'the-resource-id' }
  let(:kind){ 'some-kind' }
  let(:account){ 'the-account' }
  let(:resourceid){ [account, kind, identifier].join ':'}
  let(:options){ { } }
  let(:raw_annotations){ [{'name' => 'name', 'value' => 'bar'}, 
                      {'name' => 'comment', 'value' => 'some comment'}] }
  let(:attributes){ { 'annotations' => raw_annotations } }

  let(:resource){
    double('resource', attributes: attributes, account: account,
           kind: kind, identifier: identifier, resourceid: resourceid,
           options: options
      ) }

  let(:annotations){ Conjur::Annotations.new(resource) }
  
  subject { annotations }

  let(:url){ "#{Conjur::Authz::API.host}/#{account}/annotations/#{kind}/#{identifier}" }

  def expect_put_request url, payload
    expect(RestClient::Request).to receive(:execute).with(
      method: :put,
      headers: {},
      url: url,
      payload: payload
    )
  end
  
  describe '[]' do
    it "returns annotations" do
      expect(subject[:name]).to eq('bar')
      expect(subject[:comment]).to eq('some comment')
      expect(subject['comment']).to eq(subject[:comment])
    end
    
    it "caches the get result" do
      expect(resource).to receive(:attributes).exactly(1).times.and_return(attributes)
      subject[:name]
      subject[:name]
    end
  end
  
  describe '#each' do
    it "yields each annotation pair" do
      pairs = []
      subject.each{|k,v| pairs << [k,v]}
      expect(pairs).to eq([[:name, 'bar'], [:comment, 'some comment']])
    end
  end

  it "is Enumerable" do
    expect(subject).to be_a(Enumerable)
  end
  
  describe '#to_h' do
    it "returns the correct hash" do
      expect(subject.to_h).to eq({name: 'bar', comment: 'some comment'})
    end
    it "does not propagate modifications to the returned hash" do
      expect(RestClient::Request).not_to receive(:execute)
      subject.to_h[:name] = 'new name'
      expect(subject[:name]).to eq(subject.to_h[:name])
      expect(subject[:name]).to eq("bar")
    end
  end
  
  describe "#merge!" do
    let(:hash){ {blah: 'blahbah', zelda: 'link'} }
    
    it "makes a put request for each pair" do
      hash.each do |k,v|
        expect_put_request(url, name: k, value: v)
      end
      expect(resource).to receive(:invalidate).exactly(hash.count).times.and_yield
      subject.merge! hash
    end
  end
  
  describe '[]=' do

    it "makes a put request" do
      expect_put_request url, name: :blah, value: 'boo'
      expect(resource).to receive(:invalidate).and_yield
      subject[:blah] = 'boo'
    end
    
    it "forces a fresh request for the annotations" do
      expect_put_request(url, name: :foo, value: 'bar')
      expect(resource).to receive(:attributes).exactly(2).times.and_return(attributes)
      expect(resource).to receive(:invalidate).and_yield
      # One get request
      expect(subject[:name]).to eq('bar')
      # Update
      subject[:foo] = 'bar'
      # Second get request
      expect(subject[:name]).to eq('bar')
    end
  end
  
end