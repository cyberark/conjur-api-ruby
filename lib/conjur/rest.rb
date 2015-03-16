#
# Copyright (C) 2015 Conjur Inc
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

require 'rest-client'
require 'conjur/build_from_response'
require 'conjur/cast'
require 'conjur/escape'
require 'conjur/log_source'
require 'conjur/patches/rest-client'

module Conjur
# A REST resource with Conjur-related functionality.
# Base for all REST references in the library.
  class REST < RestClient::Resource
    include Conjur::Escape
    include Conjur::LogSource
    include Conjur::Cast
    extend Conjur::BuildFromResponse

    def core_conjur_account
      Conjur::Core::API.conjur_account
    end

    def to_json _options = {}
      {}
    end

    def conjur_api
      Conjur::API.new_from_token token
    end

    def token
      authorization = options[:headers][:authorization]
      if authorization && (token = authorization.to_s[/^Token token="(.*)"/, 1])
        JSON.parse(Base64.decode64(token))
      else
        fail AuthorizationError, "Authorization missing"
      end
    end

    def username
      options[:user] || options[:username]
    end
  end
end
