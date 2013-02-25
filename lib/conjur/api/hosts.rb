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

    def enroll_host(key)
      log do |logger|
        logger << "Enrolling #{id}"
      end
      mime_type = body = nil
      RestClient::Resource.new("#{Conjur::Core::API.host}/hosts/enroll?key=#{query_escape key}", credentials).get do |response|
        mime_type = response.headers[:content_type]
        body = response.body
      end
      [ mime_type, body ]
    end
    
    def host id
      Host.new("#{Conjur::Core::API.host}/hosts/#{path_escape id}", credentials)
    end
  end
end
