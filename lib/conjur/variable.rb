module Conjur
  class Variable < RestClient::Resource
    include ActsAsResource
    include HasAttributes
    include Exists
    include HasId
    
    def add_value value
      invalidate do
        self['values'].post value: value
      end
    end
    
    def version_count
      self.attributes['versions']
    end
    
    def value(version = nil)
      url = 'value'
      url << "?version=#{version}" if version
      self[url].get.body
    end
  end
end
