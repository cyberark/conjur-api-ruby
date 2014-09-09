require 'spec_helper'

describe Conjur::Host, api: :dummy do
  subject { Conjur::Host.new 'http://example.com/hosts/my%2Fhostname', nil }

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
end
