#!/usr/bin/env ruby
# a hackish script to gauge the time it takes to load various components

$require_level = 0
alias :orig_require :require
def require(file)
  rl = $require_level
  r0 = Time.now
  $require_level += 1
  r = orig_require(file)
  $require_level -=1
  c = caller[0][/.*?:[^:]+/]
  c = '' unless c =~ /conjur/
  printf "%5.02f %s %s %s\n", Time.now - r0, '-' * rl, file, c + (r ? '' : ' (already required)')
  r
end

$: << 'lib'
require 'date'
require 'conjur/api'
