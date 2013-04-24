module Conjur
  class Host < RestClient::Resource
    include Exists
    include HasId
    include HasIdentifier
    include HasAttributes
    include ActsAsUser
    
    def login
      [ 'host', id ].join('/')
    end
    
    def api_key
      self.attributes['api_key']
    end
    
    def enrollment_url
      log do |logger|
        logger << "Fetching enrollment_url for #{id}"
      end
      self['enrollment_url'].head{|response, request, result| response }.headers[:location]
    end
  end
end
