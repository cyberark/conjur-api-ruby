require 'conjur/host'

module Conjur
  class API
    class << self
      def enroll_host(url)
        if Conjur.log
          logger << "Enrolling host with URL #{url}"
        end
        require 'uri'
        url = URI.parse(url) if url.is_a?(String)
        response = Net::HTTP.get_response url
        raise "Host enrollment failed with status #{response.code} : #{response.body}" unless response.code.to_i == 200
        mime_type = response['Content-Type']
        body = response.body
        [ mime_type, body ]
      end
    end
    
    def create_host options
      standard_create Conjur::Core::API.host, :host, nil, options
    end
    
    def host id
      standard_show Conjur::Core::API.host, :host, id
    end
  end
end
