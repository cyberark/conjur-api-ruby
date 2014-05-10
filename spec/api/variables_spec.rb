require 'spec_helper'
require 'standard_methods_helper'


describe Conjur::API, api: :dummy do
  describe '#create_variable' do
    let(:invoke) { api.create_variable :type, :kind, other: true }
    it_should_behave_like 'standard_create with', :variable, nil, mime_type: :type, kind: :kind, other: true
  end

  describe '#variable' do
    let(:invoke) { api.variable :id }
    it_should_behave_like 'standard_show with', :variable, :id
  end

  describe "#variable_values" do

    it 'requires non-empty array of variables' do
      expect { api.variable_values("something") }.to raise_exception(ArgumentError)
      expect { api.variable_values([]) }.to raise_exception(ArgumentError)
    end 

    describe "returns Hash consisting of variables values" do
      let (:varlist) { ["var/1","var/2","var/3" ] }
      let (:expected_url) { "#{core_host}/variables/values?vars=#{varlist.map {|v| api.fully_escape(v) }.join(",")}"  }
      let (:return_code) { '200' }
      let (:return_body) { '{"var/1":"val1","var/2":"val2","var/3":"val3"}' }
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
      let (:invoke) { api.variable_values(varlist) }
      describe "raises expected errors" do
        let (:return_error) { RestClient::ResourceNotFound }
        it "does not suppress RestClient errors" do
          expect { invoke }.to raise_error(return_error)
        end
      end
      it 'returns Hash of values' do
        invoke.should == { "var/1"=>"val1", "var/2"=>"val2", "var/3"=>"val3" }
      end  
    end

  end

end
