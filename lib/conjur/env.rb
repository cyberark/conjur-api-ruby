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
  extend self

  # @deprecated
  # @api private
  # This method delegates to {Conjur::Configuration#service_base_port}
  #
  # @return [Integer] the service base port
  def service_base_port
    Conjur.configuration.service_base_port
  end

  # This method delegates to {Conjur::Configuration#account}
  #
  # @return [String] the value of `Conjur.configuration.account`
  def account
    Conjur.configuration.account
  end

  # This method delegates to {Conjur::Configuration#env}
  # @return [String] the value of `Conjur.configuration.env`
  def env
    Conjur.configuration.env
  end

  # @api private
  # @deprecated
  # This method delegates to {Conjur::Configuration#stack}
  #
  # @return [String] the value of `Conjur.configuration.stack`
  def stack
    Conjur.configuration.stack
  end
end