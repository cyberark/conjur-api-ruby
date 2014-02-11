#
# Copyright (C) 2013 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'conjur/annotations'

module Conjur
  class Resource < RestClient::Resource
    include Exists
    include HasAttributes
    include PathBased
    
    def identifier
      match_path(3..-1)
    end
    
    # Name convention according to Role#roleid.  
    def resourceid 
      [account, kind, identifier].join ':'
    end
    
    alias :resource_id :resourceid
    
    def create(options = {})
      log do |logger|
        logger << "Creating resource #{kind}:#{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self.put(options)
    end

    # Lists roles that have a specified permission on the resource.
    def permitted_roles(permission, options = {})
      JSON.parse RestClient::Resource.new(Conjur::Authz::API.host, self.options)["#{account}/roles/allowed_to/#{permission}/#{path_escape kind}/#{path_escape identifier}"].get(options)
    end
    
    # Changes the owner of a resource
    def give_to(owner, options = {})
      owner = cast(owner, :roleid)
      self.put(options.merge(owner: owner))
    end

    def delete(options = {})
      log do |logger|
        logger << "Deleting resource #{kind}:#{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      super options
    end

    def permit(privilege, role, options = {})
      role = cast(role, :roleid)
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Permitting #{p} on resource #{kind}:#{identifier} by #{role}"
          unless options.empty?
            logger << " with options #{options.to_json}"
          end
        end
        
        begin
          self["?permit&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
        rescue RestClient::Forbidden
          # TODO: Remove once permit is idempotent
          raise $! unless $!.http_body == "Privilege already granted."
        end
      end
    end
    
    def deny(privilege, role, options = {})
      role = cast(role, :roleid)
      eachable(privilege).each do |p|
        log do |logger|
          logger << "Denying #{p} on resource #{kind}:#{identifier} by #{role}"
          unless options.empty?
            logger << " with options #{options.to_json}"
          end
        end
        self["?deny&privilege=#{query_escape p}&role=#{query_escape role}"].post(options)
      end
    end

    # True if the logged-in role, or a role specified using the acting-as option, has the
    # specified +privilege+ on this resource.
    def permitted?(privilege, options = {})
      self["?check&privilege=#{query_escape privilege}"].get(options)
      true
    rescue RestClient::ResourceNotFound
      false
    end
    
    # Return a Conjur::Annotations instance to read and manipulate our annotations.
    def annotations
      @annotations ||= Conjur::Annotations.new(self)
    end
    alias tags annotations

    # Returns all resources (optionally qualified by kind)
    # visible to the user with given credentials.
    # Options are:
    # - host - authz url,
    # - credentials,
    # - account,
    # - kind (optional).
    def self.all opts = {}
      host, credentials, account, kind = opts.values_at(*[:host, :credentials, :account, :kind])
      fail ArgumentError, "host and account are required" unless [host, account].all?

      credentials ||= {}

      path = "#{account}/resources"
      path += "/#{kind}" if kind
      resource = RestClient::Resource.new(host, credentials)[path]
      JSON.parse resource.get
    end

    protected
    
    def eachable(item)
      item.respond_to?(:each) ? item : [ item ]
    end
  end
end
