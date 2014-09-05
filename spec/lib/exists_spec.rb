require 'spec_helper'

describe Conjur::Exists do
  subject(:resource) { Object.new.tap {|o| o.send :extend, Conjur::Exists } }

  describe '#exists?' do
    subject { resource.exists? }

    context "when head returns 200" do
      before { allow(resource).to receive_messages head: "" }
      it { is_expected.to be_truthy }
    end

    context "when forbidden" do
      before { allow(resource).to receive(:head) { raise RestClient::Forbidden }}
      it { is_expected.to be_truthy }
    end

    context "when not found" do
      before { allow(resource).to receive(:head) { raise RestClient::ResourceNotFound }}
      it { is_expected.to be_falsey }
    end
  end
end
