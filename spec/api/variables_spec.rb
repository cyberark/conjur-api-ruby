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


  let (:expected_url) { nil }
  let (:expected_headers) { {} }
  shared_context "Stubbed API" do
    before {
      expect_request(
        method: :get,
        url: expected_url,
        headers: credentials[:headers].merge(expected_headers)
        ) { 
        if defined? return_error 
          raise return_error
        else
          double( code: return_code, body: return_body ) 
        end
      }
    }
  end

  describe "#variable_values" do

    let (:varlist) { ["var/1","var/2","var/3" ] }

    it 'requires non-empty array of variables' do
      expect { api.variable_values("something") }.to raise_exception(ArgumentError)
      expect { api.variable_values([]) }.to raise_exception(ArgumentError)
    end 

    let (:expected_url) { "#{core_host}/variables/values?vars=#{varlist.map {|v| api.fully_escape(v) }.join(",")}"  }

    let (:invoke) { api.variable_values(varlist) }

    describe "if '/variables/values' method is responding with JSON" do
      include_context "Stubbed API"
      let (:return_code) { '200' }
      let (:return_body) { '{"var/1":"val1","var/2":"val2","var/3":"val3"}' }
      it "returns Hash of values built from the response" do  
        expect(api).not_to receive(:variable)
        expect(invoke).to eq({ "var/1"=>"val1", "var/2"=>"val2", "var/3"=>"val3" })
      end
    end 

    describe "if '/variables/values' method is returning 404 error" do
      include_context "Stubbed API"
      let (:return_error) { RestClient::ResourceNotFound }
      before {  
        expect(api).to receive(:variable).with("var/1").and_return(double(value:"val1_obtained_separately"))
        expect(api).to receive(:variable).with("var/2").and_return(double(value:"val2_obtained_separately"))
        expect(api).to receive(:variable).with("var/3").and_return(double(value:"val3_obtained_separately"))
      }
      it 'tries variables one by one and returns Hash of values' do
        expect(invoke).to eq({ "var/1"=>"val1_obtained_separately", 
                           "var/2"=>"val2_obtained_separately", 
                           "var/3"=>"val3_obtained_separately" 
                          })
      end
    end 
    
    describe "if '/variables/values' method is returning any other error" do
      include_context "Stubbed API"
      let (:return_error) { RestClient::Forbidden }
      it 're-raises error without checking particular variables' do 
        expect(api).not_to receive(:variable)
        expect { invoke }.to raise_error(return_error)
      end
    end 

  end

  describe '#variable_expirations' do
    include_context "Stubbed API"
    let (:expected_url) { "#{core_host}/variables/expirations" }
    let (:return_code) { '200' }
    let (:return_body) { '[]' }

    context "with no interval" do
      subject {api.variable_expirations}
      it { is_expected.to eq([]) }
    end

    context "with interval" do
      let (:interval) { 2.weeks }
      let (:expected_headers) { {:params => { :duration => "PT#{interval.to_i}S" } } }
      subject { api.variable_expirations(2.weeks) }
      it { is_expected.to eq([]) }
    end

  end

end
