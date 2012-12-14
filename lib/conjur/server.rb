module Conjur
  class Server < RestClient::Resource
    def generate_enrollment_script
      self['/enroll'].head{|response, request, result| response }.headers[:location]
    end
  end
end
