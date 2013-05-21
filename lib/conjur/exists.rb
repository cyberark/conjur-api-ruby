module Conjur
  module Exists
    def exists?(options = {})
      begin
        self.head(options)
        true
      rescue RestClient::Forbidden
        # rationale is: exists? should return true iff creating a resource with
        # the same name would fail (not by client's fault). Why it would fail
        # doesn't matter that much.
        # (Plus, currently it always 403s when the resource exists but is unaccessible.)
        true
      rescue RestClient::ResourceNotFound
        false
      end
    end
  end
end