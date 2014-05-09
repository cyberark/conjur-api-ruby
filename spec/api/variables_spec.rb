require 'spec_helper'
require 'standard_methods_helper'

shared_examples_for "raises expected errors" do
  let (:return_error) { RestClient::ResourceNotFound }

  it "fails with error" do
    expect { invoke }.to raise_error(return_error)
  end
 
end

shared_context "stubbed bundle REST API" do
  let (:varlist) { ["var/1","var/2","var/3" ] }
  let (:base_url) { "#{core_host}/variables/bundle?vars=#{varlist.map {|v| api.fully_escape(v) }.join(",")}"  }
  before {
    RestClient::Request.should_receive(:execute).with(
      method: :get,
      url: expected_url,
      headers: credentials[:headers]
      ).and_return { 
        if defined? return_error 
          raise return_error
        else
          double( code: return_code, body: return_body ) 
        end
      }
  }
end

describe Conjur::API, api: :dummy do
  describe '#create_variable' do
    let(:invoke) { api.create_variable :type, :kind, other: true }
    it_should_behave_like 'standard_create with', :variable, nil, mime_type: :type, kind: :kind, other: true
  end

  describe '#variable' do
    let(:invoke) { api.variable :id }
    it_should_behave_like 'standard_show with', :variable, :id
  end

  describe "#variables_bundle" do

    it 'requires non-empty array of variables' do
      expect { api.variables_bundle("something") }.to raise_exception(ArgumentError)
      expect { api.variables_bundle([]) }.to raise_exception(ArgumentError)
    end 

    describe "when called without check parameter" do
      include_context "stubbed bundle REST API"
      let (:invoke) { api.variables_bundle(varlist) }
      let (:expected_url) { base_url }
      let (:return_code) { '200' }
      let (:return_body) { '{"var/1":"val1","var/2":"val2","var/3":"val3"}' }
      it_behaves_like "raises expected errors"
      it 'returns Hash of values' do
        invoke.should == { "var/1"=>"val1", "var/2"=>"val2", "var/3"=>"val3" }
      end  
    end 

    describe "when called with additional :check parameter" do
      include_context "stubbed bundle REST API"
      let (:invoke) { api.variables_bundle(varlist, check: true) }
      let (:expected_url) { base_url+"&check" }
      let(:return_code) { "204" }
      let(:return_body) { " " }
      it_behaves_like "raises expected errors"
      it 'returns True if variables are readable' do
        invoke.should == true
      end 
    end
  end

end
