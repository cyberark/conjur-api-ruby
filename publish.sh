#!/usr/bin/env bash
set -e

summon --yaml "RUBYGEMS_API_KEY: !var rubygems/api-key" \
  publish-rubygem conjur-api
