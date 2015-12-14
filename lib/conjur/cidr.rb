#
# Copyright (C) 2015 Conjur Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
##
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
  # Utility methods for CIDR network addresses
  module CIDR
    # Parse addr into an IPAddr if it's not one already, then extend it with CIDR
    # module. This will force validation and will raise ArgumentError if invalid.
    def self.validate addr
      addr = IPAddr.new addr unless addr.kind_of? IPAddr
      addr.extend self
    end

    def self.extended addr
      addr.prefixlen # validates
    end

    # Error raised when an address is not a valid CIDR network address
    class InvalidCIDR < ArgumentError
    end

    attr_reader :mask_addr

    # Returns the length of the network mask prefix
    def prefixlen
      unless @prefixlen
        @prefixlen = 0
        mask = mask_addr
        addr = to_i

        while (mask & 1) == 0
          mask >>= 1
          addr >>= 1
        end

        while addr != 0 && (mask & 1) == 1
          mask >>= 1
          addr >>= 1
          @prefixlen += 1
        end

        if mask != 0 || addr != 0
          fail InvalidCIDR, "#{inspect} is not a valid CIDR network address"
        end
      end
      return @prefixlen
    end
  end
end
