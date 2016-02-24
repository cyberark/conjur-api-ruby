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
require 'conjur/variable'

module Conjur
  class API
    #@!group Directory: Variables

    # Create a {http://developer.conjur.net/reference/services/directory/variable Conjur Variable}.
    # See {Conjur::Variable} for operations on Conjur variables.
    #
    # ### Permissions
    # Any authenticated role may call this method
    #
    # @example Create a variable to store a database connection string
    #   db_uri = "mysql://username:password@mysql.somehost.com/mydb"
    #   var = api.create_variable 'text/plain', 'mysql-connection-string', id: 'production/mysql/uri'
    #   var.add_value db_uri
    #
    #   # Alternatively, we could have done this:
    #   var = api.create_variable 'text/plain', 'mysql-connection-string',
    #         id: 'production/mysql/uri',
    #         value: db_uri
    #
    # @example Create a variable with a unique random id
    #   var = api.create_variable 'text/plain', 'secret'
    #   var.id # => 'kngeqg'
    #
    # @param [String] mime_type MIME type for the variable value, used to set the `"Content-Type"`header
    #   when serving the variable's value.  Must be non-empty.
    # @param [String] kind user defined `kind` for the variable.  This is useful as a simple way to document
    #   the variable's purpose.  Must be non-empty
    # @param [Hash] options options for the new variable
    # @option options [String] :id specify an id for the new variable. Must be non-empty.
    # @option options [String] :value specify an initial value for the variable
    # @return [Conjur::Variable] an object representing the new variable
    # @raise [RestClient::Conflict] if you give an `:id` option and the variable already exists
    # @raise [RestClient::UnprocessableEntity] if `mime_type`, `kind`, or `options[:id]` is the empty string.
    def create_variable(mime_type, kind, options = {})
      standard_create Conjur::Core::API.host, :variable, nil, options.merge(mime_type: mime_type, kind: kind)
    end

    # Retrieve an object representing a {http://developer.conjur.net/reference/services/directory/variable Conjur Variable}.
    # The {Conjur::Variable} returned may or may not exist, and
    # your permissions on the corresponding resource determine the operations you can perform on it.
    #
    # ### Permissions
    # Any authenticated role can call this method.
    #
    # @param [String] id the unqualified id of the variable
    # @return [Conjur::Variable] and object representing the variable.
    def variable id
      standard_show Conjur::Core::API.host, :variable, id
    end

    # Fetch the values of a list of variables.  This operation is more efficient than fetching the
    # values one by one.
    #
    # This method will fail unless:
    #   * All of the variables exist
    #   * You have permission to `'execute'` all of the variables
    #
    # @example Fetch multiple variable values
    #   values = variable_values ['postgres_uri', 'aws_secret_access_key', 'aws_access_key_id']
    #   values # =>
    #   {
    #      "postgres_uri" => "postgres://..."
    #      "aws_secret_access_key" => "..."
    #      "aws_access_key_id" => "..."
    #   }
    #
    # This method is used to implement the {http://developer.conjur.net/reference/tools/utilities/conjurenv `conjur env`}
    # commands.  You may consider using that instead to run your program in an environment with the necessary secrets.
    #
    # @param [Array<String>] varlist list of variable ids to fetch
    # @return [Hash] a hash mapping variable ids to variable values
    # @raise [RestClient::Forbidden, RestClient::ResourceNotFound] if any of the variables don't exist or aren't accessible.
    def variable_values(varlist)
      raise ArgumentError, "Variables list must be an array" unless varlist.kind_of? Array 
      raise ArgumentError, "Variables list is empty" if varlist.empty?
      opts = "?vars=#{varlist.map { |v| fully_escape(v) }.join(',')}"
      begin 
        resp = RestClient::Resource.new(Conjur::Core::API.host, self.credentials)['variables/values'+opts].get
        return JSON.parse( resp.body ) 
      rescue RestClient::ResourceNotFound 
        return Hash[ *varlist.map { |v| [ v, variable(v).value ]  }.flatten ]  
      end
    end

    # Fetch all visible variables that expire within the given
    # interval (relative to the current time on the Conjur Server). If
    # no interval is specifed, all variables that are set to expire
    # will be returned.
    #
    # interval should either be a String containing an ISO8601
    # duration, or it should implement #to_i to return a number of
    # seconds.
    #
    # @example Use an ISO8601 duration to return variables expiring in the next month
    #   expirations = api.variable_expirations('P1M')
    #
    # @example Use ActiveSupport to return variables expiring in the next month
    #   require 'active_support/all'
    #   expirations = api.variable_expirations(1.month)

    # param interval a String containing an ISO8601 duration , or a number of seconds 
    # return [Hash] variable expirations that occur within the interval
    def variable_expirations(interval = nil)
      duration = interval.try { |i| i.respond_to?(:to_str) ? i : "PT#{i.to_i}S" }
      params = {}
      params[:params] = {:duration => duration} if duration
      JSON.parse(RestClient::Resource.new(Conjur::Core::API.host, self.credentials)['variables/expirations'].get(params).body).collect do |item|
        # the JSON objects from /variable/expirations look like
        # resources rather than variables, so their ids are
        # fully-qualified.
        variable(item['id'].split(':')[-1])
      end
    end

    #@!endgroup
  end
end
