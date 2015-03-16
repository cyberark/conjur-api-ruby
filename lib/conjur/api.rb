#
# Copyright (C) 2013-2015 Conjur Inc
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
require 'active_support'
require 'active_support/deprecation'

require 'conjur/cast'
require 'conjur/configuration'
require 'conjur/env'
require 'conjur/base'
require 'conjur/build_from_response'
require 'conjur/acts_as_resource'
require 'conjur/acts_as_role'
require 'conjur/acts_as_user'
require 'conjur/log_source'
require 'conjur/has_attributes'
require 'conjur/has_identifier'
require 'conjur/has_id'
require 'conjur/acts_as_asset'
require 'conjur/authn-api'
require 'conjur/authz-api'
require 'conjur/audit-api'
require 'conjur/core-api'
require 'conjur/layer-api'
require 'conjur/pubkeys-api'
require 'conjur/rest'
require 'conjur-api/version'
