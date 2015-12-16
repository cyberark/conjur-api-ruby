require 'spec_helper'

describe Conjur::Host, api: :dummy do
  subject(:host) { Conjur::Host.new 'http://example.com/hosts/my%2Fhostname', nil }

  describe '#resource' do
    subject { super().resource }
    it { is_expected.to be }
  end

  describe '#login' do
    subject { super().login }
    it { is_expected.to eq('host/my/hostname') }
  end

  it "fetches enrollment_url" do
    stub_request(:head, "http://example.com/hosts/my%2Fhostname/enrollment_url").
         to_return(:status => 200, :headers => {location: 'foo'})
    expect(subject.enrollment_url).to eq('foo')
  end

  describe '#update' do
    it "calls set_cidr_restrictions if given CIDR" do
      expect(host).to receive(:set_cidr_restrictions).with(['192.0.2.0/24'])
      host.update cidr: ['192.0.2.0/24']

      expect(host).to_not receive(:set_cidr_restrictions)
      host.update foo: 42
    end
  end
end
