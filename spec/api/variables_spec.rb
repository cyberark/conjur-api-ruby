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

    let (:varlist) { ["var/1","var/2","var/3" ] }

    it 'requires non-empty array of variables' do
      expect { api.variable_values("something") }.to raise_exception(ArgumentError)
      expect { api.variable_values([]) }.to raise_exception(ArgumentError)
    end 

    shared_context "Stubbed API" do
      let (:expected_url) { "#{core_host}/variables/values?vars=#{varlist.map {|v| api.fully_escape(v) }.join(",")}"  }
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

    let (:invoke) { api.variable_values(varlist) }

    describe "if '/variables/values' method is responding with JSON" do
      include_context "Stubbed API"
      let (:return_code) { '200' }
      let (:return_body) { '{"var/1":"val1","var/2":"val2","var/3":"val3"}' }
      it "returns Hash of values built from the response" do  
        api.should_not_receive(:variable)
        invoke.should == { "var/1"=>"val1", "var/2"=>"val2", "var/3"=>"val3" }
      end
    end 

    describe "if '/variables/values' method is returning 404 error" do
      include_context "Stubbed API"
      let (:return_error) { RestClient::ResourceNotFound }
      before {  
        api.should_receive(:variable).with("var/1").and_return(double(value:"val1_obtained_separately"))
        api.should_receive(:variable).with("var/2").and_return(double(value:"val2_obtained_separately"))
        api.should_receive(:variable).with("var/3").and_return(double(value:"val3_obtained_separately"))
      }
      it 'tries variables one by one and returns Hash of values' do
        invoke.should == { "var/1"=>"val1_obtained_separately", 
                           "var/2"=>"val2_obtained_separately", 
                           "var/3"=>"val3_obtained_separately" 
                          }
      end
    end 
    
    describe "if '/variables/values' method is returning any other error" do
      include_context "Stubbed API"
      let (:return_error) { RestClient::Forbidden }
      it 're-raises error without checking particular variables' do 
        api.should_not_receive(:variable)
        expect { invoke }.to raise_error(return_error)
      end
    end 

  end

end
