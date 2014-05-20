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
  
  subject{ annotations }

  let(:url){ "#{Conjur::Authz::API.host}/#{account}/annotations/#{kind}/#{identifier}" }

  def expect_put_request url, payload
    RestClient::Request.should_receive(:execute).with(
      method: :put,
      headers: {},
      url: url,
      payload: payload
    )
  end
  
  describe '[]' do
    it "returns annotations" do
      subject[:name].should == 'bar'
      subject[:comment].should == 'some comment'
      subject['comment'].should == subject[:comment]
    end
    
    it "caches the get result" do
      resource.should_receive(:attributes).exactly(1).times.and_return(attributes)
      subject[:name]
      subject[:name]
    end
  end
  
  describe '#each' do
    it "yields each annotation pair" do
      pairs = []
      subject.each{|k,v| pairs << [k,v]}
      pairs.should == [[:name, 'bar'], [:comment, 'some comment']]
    end
  end

  it "is Enumerable" do
    subject.should be_a(Enumerable)
  end
  
  describe '#to_h' do
    it "returns the correct hash" do
      subject.to_h.should == {name: 'bar', comment: 'some comment'}
    end
    it "does not propagate modifications to the returned hash" do
      RestClient::Request.should_not_receive(:execute)
      subject.to_h[:name] = 'new name'
      subject[:name].should == subject.to_h[:name]
      subject[:name].should == "bar"
    end
  end
  
  describe "#merge!" do
    let(:hash){ {blah: 'blahbah', zelda: 'link'} }
    
    it "makes a put request for each pair" do
      hash.each do |k,v|
        expect_put_request(url, name: k, value: v)
      end
      resource.should_receive(:invalidate).exactly(hash.count).times
      subject.merge! hash
    end
  end
  
  describe '[]=' do

    it "makes a put request" do
      expect_put_request url, name: :blah, value: 'boo'
      resource.should_receive :invalidate
      subject[:blah] = 'boo'
    end
    
    it "forces a fresh request for the annotations" do
      expect_put_request(url, name: :foo, value: 'bar')
      resource.should_receive(:attributes).exactly(2).times.and_return(attributes)
      resource.should_receive(:invalidate)
      # One get request
      subject[:name].should == 'bar'
      # Update
      subject[:foo] = 'bar'
      # Second get request
      subject[:name].should == 'bar'
    end
  end
  
end