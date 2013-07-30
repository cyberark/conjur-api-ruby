module Conjur
  module StandardMethods
    require 'active_support/core_ext'
    
    protected
    
    def standard_create(host, type, id = nil, options = nil)
      log do |logger|
        logger << "Creating #{type}"
        logger << " #{id}" if id
        unless options.blank?
          logger << " with options #{options.inspect}"
        end
      end
      options ||= {}
      options[:id] = id if id
      resp = RestClient::Resource.new(host, credentials)[type.to_s.pluralize].post(options)
      "Conjur::#{type.to_s.classify}".constantize.build_from_response(resp, credentials)
    end
    
    def standard_list(host, type, options)
      JSON.parse(
        RestClient::Resource.new(host, credentials)[type.to_s.pluralize]
                            .get(options)
      ).collect do |json|
        json['resource_id']
      end
    end
    
    def standard_show(host, type, id)
      "Conjur::#{type.to_s.classify}".constantize.new(host, credentials)[ [type.to_s.pluralize, fully_escape(id)].join('/') ]
    end
  end
end
