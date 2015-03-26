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
require 'conjur/deputy'

module Conjur
  class API
    #@!group Directory: Deputies

    # @api internal
    #
    # Create a Conjur deputy.
    #
    # Deputies are used internally by Conjur services that need to perform
    # actions as a particular role.  While the deputies API is stable,
    # it isn't intended for use by end users.
    #
    # @param [Hash] options options for deputy creation
    # @option options [String] :id the *unqualified* id for the new deputy.  If not present,
    #   the deputy will be given a randomly generated id.
    # @return [Conjur::Deputy] the new deputy
    # @raise [RestClient::Conflict] if a deputy already exists with the given id.
    def create_deputy options = {}
      standard_create Conjur::Core::API.host, :deputy, nil, options
    end

    # @api internal
    #
    # Find a Conjur deputy by id.
    # Deputies are used internally by Conjur services that need to perform
    # actions as a particular role.  While the deputies API is stable,
    # it isn't intended for use by end users.
    #
    # @param [String] id the deputy's *unqualified* id
    # @return [Conjur::Deputy] the deputy, which may or may not exist.
    def deputy id
      standard_show Conjur::Core::API.host, :deputy, id
    end
  end
end