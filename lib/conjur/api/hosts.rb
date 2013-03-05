require 'conjur/host'

module Conjur
  class API
    def create_host options
      log do |logger|
        logger << "Creating host"
      end
      resp = RestClient::Resource.new("#{Conjur::Core::API.host}/hosts", credentials).post(options)
      Host.new(resp.headers[:location], credentials).tap do |host|
        log do |logger|
          logger << "Created host "
          logger << host.id
        end
      end
    end
    
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
    
    def host id
      Host.new("#{Conjur::Core::API.host}/hosts/#{path_escape id}", credentials)
    end
  end
end
