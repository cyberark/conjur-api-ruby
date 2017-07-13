#!/bin/bash -ex

function finish {
  docker-compose down
}
trap finish EXIT

# Generate reports folders locally
mkdir -p spec/reports features/reports

# Build test container & start the cluster
docker-compose build
docker-compose up -d

# Delay to allow time for Possum to come up
# TODO: remove this once we have HEALTHCHECK in place
sleep 20

api_key=$(docker-compose exec -T possum rails r "print Credentials['cucumber:user:admin'].api_key")

# Execute tests
docker-compose exec -T tests \
  env CONJUR_AUTHN_API_KEY="$api_key" \
  bash -c 'ci/test.sh'
