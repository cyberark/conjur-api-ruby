require 'aruba/cucumber'
require 'conjur/cli'

Conjur::Config.load
Conjur::Config.apply
$conjur = Conjur::Authn.connect nil, noask: true
