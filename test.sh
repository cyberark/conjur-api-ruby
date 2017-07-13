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

# provide time for all services to start
# TODO once service startup check is working in Possum, we should use that check instead of just waiting.
sleep 5

# Generate a new account `cucumber` and extract the API key so we can log in for CI tests
api_key=$(docker-compose exec possum possum account create cucumber | tail -1 | awk '{print $4}' | tr -d '\r')

# Execute tests
docker-compose exec tests env CONJUR_AUTHN_API_KEY="$api_key" bash -c 'ci/test.sh'
