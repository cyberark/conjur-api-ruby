require 'spec_helper'

describe Conjur::Exists do
  subject { Object.new.tap {|o| o.send :extend, Conjur::Exists } }

  context "when head returns 200" do
    before { subject.stub head: "" }

    describe '#exists?' do
      subject { super().exists? }
      it { is_expected.to be_truthy }
    end
  end

  context "when forbidden" do
    before { allow(subject).to receive(:head) { raise RestClient::Forbidden }}
    it "returns true" do
      expect(subject.exists?).to be_truthy
    end
  end

  context "when not found" do
    before { allow(subject).to receive(:head) { raise RestClient::ResourceNotFound }}

    describe '#exists?' do
      subject { super().exists? }
      it { is_expected.to be_falsey }
    end
  end
end
