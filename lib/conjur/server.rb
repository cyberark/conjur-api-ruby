module Conjur
  class Server < RestClient::Resource
    include Exists
    include HasIdentifier
    include HasAttributes
    include ActsAsResource
    
    def generate_enrollment_script
      self['/enroll'].head{|response, request, result| response }.headers[:location]
    end
  end
end
