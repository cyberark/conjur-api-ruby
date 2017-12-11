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
  runTests5
  runTests4
}

function startConjur() {
  echo 'Starting Conjur environment'
  echo '-----'
  docker-compose pull
  docker-compose build
  docker-compose up -d pg conjur_4 conjur_5
}

function runTests5() {
  echo 'waiting for Conjur v5 to come up...'
  # TODO: remove this once we have HEALTHCHECK in place
  docker-compose run --rm tester ./ci/wait_for_server.sh

  local api_key=$(docker-compose exec -T conjur_5 rake rake 'role:retrieve-key[cucumber:user:admin]')

  echo 'Running tests'
  echo '-----'
  docker-compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    tester_5
}

function runTests4() {
  echo 'waiting for Conjur v4 to come up...'
  # TODO: remove this once we have HEALTHCHECK in place
  docker-compose exec -T conjur_4 /opt/conjur/evoke/bin/wait_for_conjur
  docker-compose exec -T conjur_4 evoke ca regenerate conjur_4
  docker-compose exec -T conjur_4 /opt/conjur/evoke/bin/wait_for_conjur
  docker-compose exec -T conjur_4 cat /opt/conjur/etc/ssl/ca.pem > ./tmp/conjur.pem

  local api_key=$(docker-compose exec -T conjur_4 conjur-plugin-service authn rails r "puts User['admin'].api_key")

  echo 'Running tests'
  echo '-----'
  docker-compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    tester_4
}
main
