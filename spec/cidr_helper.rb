shared_examples_for "CIDR create" do
  it "formats the CIDRs correctly" do
    cidrs = %w(192.0.2.0/24 198.51.100.0/24)
    expect do
      create cidr: cidrs.map(&IPAddr.method(:new))
    end.to call_standard_create_with anything, anything, hash_including(cidr: cidrs)
  end

  it "parses addresses given as strings" do
    expect do
      create cidr: %w(192.0.2.0/255.255.255.128)
    end.to call_standard_create_with anything, anything, hash_including(cidr: %w(192.0.2.0/25))
  end

  it "raises ArgumentError on invalid CIDR" do
    expect do
      create cidr: %w(192.0.2.0/255.255.0.255)
    end.to raise_error ArgumentError

    expect do
      create cidr: %w(192.0.2.256/1)
    end.to raise_error ArgumentError
  end
end
