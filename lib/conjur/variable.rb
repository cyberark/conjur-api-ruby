module Conjur
  class Variable < RestClient::Resource
    include ActsAsAsset
    
    def add_value value
      log do |logger|
        logger << "Adding a value to variable #{id}"
      end
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
