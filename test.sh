#!/bin/bash -e

: "${RUBY_VERSION=3.0}"
# My local RUBY_VERSION is set to ruby-#.#.# so this allows running locally.
RUBY_VERSION="$(cut -d '-' -f 2 <<< "$RUBY_VERSION")"

export REGISTRY_URL=${INFRAPOOL_REGISTRY_URL:-"docker.io"}

source ./ci/oauth/keycloak/keycloak_functions.sh
TOP_LEVEL=$(git rev-parse --show-toplevel)

function finish {
  echo 'Removing test environment'
  echo '---'
  docker compose down --rmi 'local' --volumes
}

trap finish EXIT

# Set up VERSION file for local development
if [ ! -f "${TOP_LEVEL}/VERSION" ]; then
  echo -n "0.0.dev" > "${TOP_LEVEL}/VERSION"
fi

function main() {
  if ! docker info >/dev/null 2>&1; then
    echo "Docker does not seem to be running, run it first and retry"
    exit 1
  fi
  # Generate reports folders locally
  mkdir -p spec/reports features/reports

  startConjur
  runTests
}

function startConjur() {
  echo 'Starting Conjur environment'
  echo '-----'

  # We want to pull to make sure we're testing against the newest release;
  # failing to ensure that has caused many mysterious failures in CI.
  # However, unconditionally pulling prevents working offline even
  # with a warm cache. So try to pull, but ignore failures.
  docker compose pull --ignore-pull-failures
  docker compose build --build-arg RUBY_VERSION="$RUBY_VERSION"
  docker compose up -d pg conjur
}

function runTests() {
  echo 'Waiting for Conjur to come up, and configuring it...'
  ./ci/configure.sh

  local api_key=$(docker compose exec -T conjur bundle exec rake 'role:retrieve-key[cucumber:user:admin]')

  echo 'Running tests'
  echo '-----'
  docker compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    -e SSL_CERT_FILE=/etc/ssl/certs/keycloak.pem \
    tester \
    "/scripts/fetch_certificate && rake jenkins_init jenkins_spec jenkins_cucumber"
}

main
