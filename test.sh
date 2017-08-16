#!/bin/bash -e

function finish {
  echo 'Removing test environment'
  echo '---'
  docker-compose down --rmi 'local' --volumes
}
trap finish EXIT

function main() {
  # Generate reports folders locally
  mkdir -p spec/reports features/reports

  startConjur
  runTests
}

function startConjur() {
  echo 'Starting Conjur environment'
  echo '-----'
  docker-compose pull conjur postgres
  docker-compose build --pull tester
  docker-compose up -d conjur
}

function runTests() {
  echo 'waiting for Conjur to come up...'
  # TODO: remove this once we have HEALTHCHECK in place
  docker-compose run --rm tester ./ci/wait_for_server.sh

  local api_key=$(docker-compose exec -T conjur rails r "print Credentials['cucumber:user:admin'].api_key")

  echo 'Running tests'
  echo '-----'
  docker-compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    tester
}

main
