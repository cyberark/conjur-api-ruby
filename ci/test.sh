#!/bin/bash -e

cd /src/conjur-api

export CONJUR_AUTHN_LOGIN=admin
export CONJUR_AUTHN_API_KEY=secret

bundle
bundle exec rake jenkins || true
