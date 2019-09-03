#
# Copyright 2013-2019 CyberArk Ltd.
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
  class API

    #@!group audit

    # Fetch a list of audit entries.
    #
    #
    # @example Fetch audit entries
    #   audit_entries = audit_show
    #   ... # =>
    # [
    #     {
    #         "facility": 80,
    #         "severity": 6,
    #         "timestamp": "2019-09-05 09:16:21 +0000",
    #         "hostname": "00ab963b2b77",
    #         "appname": "conjur",
    #         "procid": "procid",
    #         "msgid": "authn",
    #         "sdata": {
    #             "auth@43868": {
    #                 "authenticator": "authn"
    #             },
    #             "action@43868": {
    #                 "result": "success",
    #                 "operation": "authenticate"
    #             },
    #             "subject@43868": {
    #                 "role": "cyberark:user:admin"
    #             }
    #         },
    #         "message": "cyberark:user:admin successfully authenticated with authenticator authn"
    #     }
    # ]
    #
    #
    # @return [Array<String>] a list of audit entries
    #
    def audit_show
      JSON.parse(url_for(:audit_show, credentials).get.body)
    end

    #@!endgroup
  end
end
