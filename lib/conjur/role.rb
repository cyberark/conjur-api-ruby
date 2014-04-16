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

module Conjur
  class Role < RestClient::Resource
    include Conjur::Exists
    include Conjur::PathBased

    def identifier
      match_path(3..-1)
    end
    
    alias id identifier
    
    def roleid
      [ account, kind, identifier ].join(':')
    end
    
    def create(options = {})
      log do |logger|
        logger << "Creating role #{kind}:#{identifier}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self.put(options)
    end
   
    def all(options = {})
      query_string = "?all"
      
      if filter = options.delete(:filter)
        filter = [filter] unless filter.is_a?(Array)
        filter.map!{ |obj| cast(obj, :roleid) }
        (query_string << "&" << filter.to_query("filter")) unless filter.empty?
      end
      JSON.parse(self[query_string].get(options)).collect do |id|
        Conjur::Role.new(Conjur::Authz::API.host, self.options)[Conjur::API.parse_role_id(id).join('/')]
      end
    end
    
    def member_of?(other_role)
      other_role = cast(other_role, :roleid)
      not all(filter: other_role).empty?
    end
    
    def grant_to(member, options={})
      member = cast(member, :roleid)
      log do |logger|
        logger << "Granting role #{identifier} to #{member}"
        unless options.blank?
          logger << " with options #{options.to_json}"
        end
      end
      self["?members&member=#{query_escape member}"].put(options)
    end

    def revoke_from(member, options = {})
      member = cast(member, :roleid)
      log do |logger|
        logger << "Revoking role #{identifier} from #{member}"
        unless options.empty?
          logger << " with options #{options.to_json}"
        end
      end
      self["?members&member=#{query_escape member}"].delete(options)
    end

    def permitted?(resource, privilege, options = {})
      resource = cast(resource, :resourceid)
      # NOTE: in previous versions there was 'kind' passed separately. Now it is part of id
      self["?check&resource_id=#{query_escape resource}&privilege=#{query_escape privilege}"].get(options)
      true
    rescue RestClient::ResourceNotFound
      false
    end
    
    def members
      JSON.parse(self["?members"].get(options)).collect do |json|
        Conjur::RoleGrant.parse_from_json(json, self.options)
      end
    end
  end
end