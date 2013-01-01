module Conjur
  module Exists
    def exists?(options = {})
      begin
        self.head(options)
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end
  end
end