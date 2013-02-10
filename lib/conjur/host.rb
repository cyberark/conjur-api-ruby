module Conjur
  class Host < RestClient::Resource
    include Exists
    include HasId
    include HasIdentifier
    include HasAttributes
    include ActsAsResource
    include ActsAsRole
    
    def generate_enrollment_script
      self['/enroll'].head{|response, request, result| response }.headers[:location]
    end
    
    def roleid
      "host-#{id}"
    end
  end
end
