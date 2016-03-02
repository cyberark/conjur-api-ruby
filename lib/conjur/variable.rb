#
# Copyright (C) 2013-2016 Conjur Inc
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

  # Secrets stored in Conjur are represented by {http://developer.conjur.net/reference/services/directory/variable Variables}.
  # The code responsible for the actual encryption of variables is open source as part of the
  # {https://github.com/conjurinc/slosilo Slosilo} library.
  #
  # You should not generally create instances of this class directly.  Instead, you can get them from
  # {Conjur::API} methods such as {Conjur::API#create_variable} and {Conjur::API#variable}.
  #
  # Conjur variables store metadata (mime-type and secret kind) with each secret.
  #
  # Variables are *versioned*.  Storing secrets in multiple places is a bad security practice, but
  # overwriting a secret accidentally can create a major problem for development and ops teams.  Conjur
  # discourages bad security practices while avoiding ops disasters by storing all previous versions of
  # a secret.
  #
  # ### Important
  # A common pitfall when trying to access older versions of a variable is to assume that `0` is the oldest
  # version.  In fact, `0` references the *latest* version, while *1* is the oldest.
  #
  #
  # ### Permissions
  #
  # * To *read* the value of a `variable`, you must have permission to `'execute'` the variable.
  # * To *add* a value to a `variable`, you must have permission to `'update'` the variable.
  # * To *show* metadata associated with a variable, but *not* the value of the secret, you must have `'read'`
  #     permission on the variable.
  #
  #  When you create a secret, the creator role is granted all three of the above permissions.
  #
  # @example Get a variable and access its metadata and the latest value
  #   variable = api.variable 'example'
  #   puts variable.kind      # "example-secret"
  #   puts variable.mime_type # "text/plain"
  #   puts variable.value     # "supahsecret"
  #
  # @example Variable permissions
  #   # use our 'admin' api to create a variable 'permissions-example
  #   admin_var = admin_api.create_variable 'text/plain', 'example', 'permissions-example'
  #
  #   # get a 'view' to it from user 'alice'
  #   alice_var = alice_api.variable admin_var.id
  #
  #   # Initilally, all of the following raise a RestClient::Forbidden exception
  #   alice_var.attributes
  #   alice_var.value
  #   alice_var.add_value 'hi'
  #
  #   # Allow alice to see the variables attributes
  #   admin_var.permit 'read', alice
  #   alice_var.attributes # OK
  #
  #   # Allow alice to update the variable
  #   admin_var.permit 'update', alice
  #   alice_var.add_value 'hello'
  #
  #   # Notice that alice still can't see the variable's value:
  #   alice_var.value # raises RestClient::Forbidden
  #
  #   # Finally, we let alice execute the variable
  #   admin_var.permit 'execute', alice
  #   alice_var.value # 'hello'
  #
  # @example Variables are versioned
  #   var = api.variable 'version-example'
  #   # Unless you set a variables value when you create it, the variable starts out without a value and version_count
  #   # is 0.
  #   var.version_count # => 0
  #   var.value # raises RestClient::ResourceNotFound (404)
  #
  #   # Add a value
  #   var.add_value 'value 1'
  #   var.version_count # => 1
  #   var.value # => 'value 1'
  #
  #   # Add another value
  #   var.add_value 'value 2'
  #   var.version_count # => 2
  #
  #   # 'value' with no argument returns the most recent value
  #   var.value # => 'value 2'
  #
  #   # We can access older versions by their 1 based index:
  #   var.value 1 # => 'value 1'
  #   var.value 2 # => 'value 2'
  #   # Notice that version 0 of a variable is always the most recent:
  #   var.value 0 # => 'value 2'
  #
  class Variable < RestClient::Resource
    include ActsAsAsset

    # The kind of secret represented by this variable,  for example, `'postgres-url'` or
    # `'aws-secret-access-key'`.
    #
    # You must have the **`'read'`** permission on a variable to call this method.
    #
    # This attribute is only for human consumption, and does not take part in the Conjur permissions
    # model.
    #
    # @note this is **not** the same as the `kind` part of a qualified Conjur id.
    # @return [String] a string representing the kind of secret.
    def kind
      attributes['kind']
    end

    # The MIME Type of the variable's value.
    #
    # You must have the **`'read'`** permission on a variable to call this method.
    #
    # This attribute is used by the Conjur services to set a response `Content-Type` header when
    # returning the value of a variable.  Conjur applies the same MIME Type to all versions of a variable,
    # so if you plan on accessing the variable in a way that depends on a correct `Content-Type` header
    # you should make sure to store appropriate data for the mime type in all versions.
    #
    # @return [String] a MIME type, such as `'text/plain'` or `'application/octet-stream'`.
    def mime_type
      attributes['mime_type']
    end

    # Add a new value to the variable.
    #
    # You must have the **`'update'`** permission on a variable to call this method.
    #
    # @example Add a value to a variable
    #   var = api.variable 'my-secret'
    #   puts var.version_count     #  1
    #   puts var.value             #  'supersecret'
    #   var.add_value "new_secret"
    #   puts var.version_count     # 2
    #   puts var.value             # 'new_secret'
    # @param [String] value the new value to add
    # @return [void]
    def add_value value
      log do |logger|
        logger << "Adding a value to variable #{id}"
      end
      invalidate do
        self['values'].post value: value
      end
    end

    # Return the number of versions of the variable.
    #
    # You must have the **`'read'`** permission on a variable to call this method.
    #
    # @example
    #   var.version_count # => 4
    #   var.add_value "something new"
    #   var.version_count # => 5
    #
    # @return [Integer] the number of versions
    def version_count
      self.attributes['version_count']
    end

    # Return the version of a variable.
    #
    # You must have the **`'execute'`** permission on a variable to call this method.
    #
    # When no argument is given, the most recent version is returned.
    #
    # When a `version` argument is given, the method returns a version according to the following rules:
    #  * If `version` is 0, the *most recent* version is returned.
    #  * If `version` is less than 0 or greater than {#version_count}, a `RestClient::ResourceNotFound` exception
    #   will be raised.
    #  * If {#version_count} is 0, a `RestClient::ResourceNotFound` exception will be raised.
    #  * If `version` is >= 1 and `version` <= {#version_count}, the version at the **1 based** index given by `version`
    #    will be returned.
    #
    # @example Fetch all versions of a variable
    #   versions = (1..var.version_count).map do |version|
    #     var.value version
    #   end
    #
    # @example Get the current version of a variable
    #   # All of these return the same thing:
    #   var.value
    #   var.value 0
    #   var.value var.version_count
    #
    # @param [Integer] version the **1 based** version.
    # @return [String] the value of the variable
    def value(version = nil, show_expired = false)
      url = 'value'
      params = {}.tap {|h|
        h['version'] = version if version
        h['show_expired'] = show_expired if show_expired
      }
      url << '?' + params.to_query unless params.empty?
      self[url].get.body
    end

    # Set the variable to expire after the given interval. The
    # interval can either be an ISO8601 duration or it can the number
    # of seconds for which the variable should be valid. Once a
    # variable has expired, its value will no longer be retrievable.
    #
    # You must have the **`'update'`** permission on a variable to call this method.
    #
    # @example Use an ISO8601 duration to set the expiration for a variable to tomorrow
    #   var = api.variable 'my-secret'
    #   var.expires_in "P1D"
    #
    # @example Use ActiveSupport to set the expiration for a variable to tomorrow
    #   require 'active_support/all'
    #   var = api.variable 'my-secret'
    #   var.expires_in 1.day
    # @param interval a String containing an ISO8601 duration, otherwise the number of seconds before the variable xpires
    # @return [Hash] description of the variable's expiration, including the (Conjur server) time when it expires
    def expires_in interval
      duration = interval.respond_to?(:to_str) ? interval : "PT#{interval.to_i}S"
      JSON::parse(self['expiration'].post(duration: duration).body)
    end

  end
end
