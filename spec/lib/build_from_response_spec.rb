require 'spec_helper'

describe Conjur::BuildFromResponse do
  describe "::build_from_response", logging: :temp do
    let(:location) { "http://example.com" }
    let(:attrs) {{ 'some' => 'foo', 'other' => 'bar' }}
    let(:response) do
      double "response", headers: { location: location }, body: attrs.to_json
    end
    subject { double "class", name: 'some' }
    let(:constructed) { double "object" }
    let(:credentials) { "whatever" }

    before do
      subject.extend Conjur::BuildFromResponse
      expect(subject).to receive(:new).with(location, credentials).and_return constructed
      expect(constructed).to receive(:attributes=).with attrs

      constructed.extend Conjur::LogSource
      constructed.stub username: 'whatever'
    end

    it "passes the location credentials and attributes" do
      subject.build_from_response response, credentials
    end

    context "with a resource(-ish) class" do
      before do
        constructed.stub resource_kind: 'chunky', resource_id: 'bacon'
      end

      it "logs creation correctly" do
        subject.build_from_response response, credentials
        expect(log).to match(/Created chunky bacon/)
      end
    end

    context "with a id(-ish) class" do
      before do
        constructed.stub id: 'bacon'
      end

      it "logs creation correctly" do
        subject.build_from_response response, credentials
        expect(log).to match(/Created some bacon/)
      end
    end
  end
end
