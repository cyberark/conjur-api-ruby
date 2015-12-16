describe Conjur::ActsAsUser, api: :dummy do
  subject do
    api.user 'kmitnick'
  end

  describe '#set_cidr_restrictions' do
    it "sends the new restrictions to the authn server" do
      expect_request(
        headers: hash_including(content_type: :json),
        url: "http://authn.example.com/users/kmitnick",
        method: :put,
        payload: { cidr: ['192.0.2.1/32'] }.to_json
      )
      subject.set_cidr_restrictions %w(192.0.2.1)
    end

    it "resets the restrictions on the authn server if given empty cidr string" do
      expect_request(
        headers: hash_including(content_type: :json),
        url: "http://authn.example.com/users/kmitnick",
        method: :put,
        payload: { cidr: [] }.to_json
      )
      subject.set_cidr_restrictions []
    end
  end
end
