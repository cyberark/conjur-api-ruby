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
  # A Deputy is an actor, typically representing a service.  It is given a login and
  # an api key, just like {Conjur::Host}s and {Conjur::User}s, and can perform various
  # actions.
  #
  # You should not create instances of this class directly.  Instead, you can get a {Conjur::Deputy}
  # instance with {Conjur::API#deputy} or {Conjur::API#create_deputy}.
  #
  # The deputies api is stable, but is primarily used internally.
  class Deputy < RestClient::Resource
    include Exists
    include HasId
    include HasIdentifier
    include HasAttributes
    include ActsAsUser
    include ActsAsResource

    # Login for the deputy.  Of the form "deputy/<deputy-id>".
    #
    # @return [String] the login.
    def login
      [ self.class.name.split('::')[-1].downcase, id ].join('/')
    end

    # API Key that can be used to login as the deputy.
    #
    # This is only available if the {Conjur::Deputy} was returned
    # by {Conjur::API#create_deputy}.
    #
    # @return [String] the api key.
    def api_key
      self.attributes['api_key']
    end
  end
end