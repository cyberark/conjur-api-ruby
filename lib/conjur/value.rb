module Conjur
  class Value < RestClient::Resource
    include Exists
    include HasAttributes

    def resource_kind
      "conjur.value"
    end

    def resource_id
      require 'uri'
      URI.unescape URI.parse(self.url).path.split('/')[-1]
    end

    def create
      self.put
    end
  end
end
