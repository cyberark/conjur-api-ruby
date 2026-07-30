# frozen_string_literal: true

require 'spec_helper'
require 'conjur/api/version_check'

describe "Conjur::API#verify_min_server_version!", api: :dummy do
  it "passes when the server version equals the minimum" do
    allow(api).to receive(:server_version).and_return("1.21.1")

    expect(api.verify_min_server_version!("1.21.1")).to be true
  end

  it "passes when the server version is greater than the minimum" do
    allow(api).to receive(:server_version).and_return("1.22.0")

    expect(api.verify_min_server_version!("1.21.1")).to be true
  end

  it "passes when a Conjur build suffix is present and the base version is sufficient" do
    allow(api).to receive(:server_version).and_return("1.21.1.1-25")

    expect(api.verify_min_server_version!("1.21.1")).to be true
  end

  it "raises when the server version is less than the minimum" do
    allow(api).to receive(:server_version).and_return("1.20.0")

    expect { api.verify_min_server_version!("1.21.1") }.to raise_error(
      Conjur::FeatureNotAvailable, /1\.20\.0.*1\.21\.1|1\.21\.1.*1\.20\.0/
    )
  end

  it "raises FeatureNotAvailable (not ArgumentError) for an unparseable server version" do
    allow(api).to receive(:server_version).and_return("development")

    expect { api.verify_min_server_version!("1.21.1") }.to raise_error(
      Conjur::FeatureNotAvailable, /Unable to parse Conjur server version/
    )
  end
end
