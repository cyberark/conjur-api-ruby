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
require 'conjur/secret'

module Conjur
  class API

    # @api private
    #
    # Create a Conjur secret.  Secrets are a low-level construcct upon which variables
    # are built,
    #
    # @param [String] value the secret data
    # @return [Conjur::Secret] the new secret
    def create_secret(value, options = {})
      standard_create Conjur::Core::API.host, :secret, nil, options.merge(value: value)
    end

    # @api private
    #
    # Fetch a Conjur secret by id.  Secrets are a low-level construct upon which variables
    # are built, and should not generally be used directly.
    #
    # @param [String] id the *unqualified* identifier for the secret
    # @return [Conjur::Secret] an object representing the secret
    def secret id
      standard_show Conjur::Core::API.host, :secret, id
    end
  end
end