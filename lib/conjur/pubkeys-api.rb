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
require 'conjur/api'
require 'conjur/configuration'

class Conjur::Configuration
  # @!attribute pubkeys_url
  # The url for the {http://developer.conjur.net/reference/services/pubkyes Conjur public keys service}.
  #
  # @note You should not generally set this value.  Instead, Conjur will derive it from the
  #   {Conjur::Configuration#account} and {Conjur::Configuration#appliance_url}
  #   properties.
  #
  # @return [String] the pubkeys service url
  add_option :pubkeys_url do
    account_service_url 'pubkeys', 400
  end
end

class Conjur::API
  class << self
    # @api private
    #
    # Url to the pubkeys service.
    # @return [String] the url
    def pubkeys_asset_host 
      Conjur.configuration.pubkeys_url
    end
  end
end

require 'conjur/api/pubkeys'