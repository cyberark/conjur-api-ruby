module Conjur
  module BuildFromResponse
    def build_from_response(response, credentials)
      new(response.headers[:location], credentials).tap do |obj|
        obj.attributes = JSON.parse(response.body)
        if obj.respond_to?(:resource_kind)
          obj.log do |logger|
            logger << "Created #{obj.resource_kind} #{obj.resource_id}"
          end
        elsif obj.respond_to?(:id)
          obj.log do |logger|
            logger << "Created #{self.name} #{obj.id}"
          end
        end
      end
    end
  end
end