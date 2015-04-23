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
  module Cast
    protected

    # Convert a value to a role or resource identifier.
    #
    # @param [String, Array, #roleid, #resourceid] obj the value to cast
    # @param [Symbol] kind must be either `:roleid` or `:resourceid`
    def cast(obj, kind)
      case kind
      when :roleid, :resourceid
        if obj.is_a?(String)
          obj
        elsif obj.is_a?(Array)
          obj.join(':')
        elsif obj.respond_to?(kind)
          obj.send(kind)
        else
          raise "I don't know how to cast a #{obj.class} to a #{kind}"
        end
      else
        raise "I don't know how to convert things to a #{kind}"
      end
    end
  end
end
