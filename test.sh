#!/bin/bash -e

: "${RUBY_VERSION=3.1}"
# My local RUBY_VERSION is set to ruby-#.#.# so this allows running locally.
RUBY_VERSION="$(cut -d '-' -f 2 <<< "$RUBY_VERSION")"


function finish {
  echo 'Removing test environment'
  echo '---'
  docker-compose down --rmi 'local' --volumes
}

trap finish EXIT

# Set up VERSION file for local development
if [ ! -f "./VERSION" ]; then
  echo -n "0.0.dev" > ./VERSION
fi

function main() {
  if ! docker info >/dev/null 2>&1; then
    echo "Docker does not seem to be running, run it first and retry"
    exit 1
  fi
  # Generate reports folders locally
  mkdir -p spec/reports features/reports features_v4/reports

  startConjur
  runTests_5
  runTests_4
}

function startConjur() {
  echo 'Starting Conjur environment'
  echo '-----'

  # We want to pull to make sure we're testing against the newest release;
  # failing to ensure that has caused many mysterious failures in CI.
  # However, unconditionally pulling prevents working offline even
  # with a warm cache. So try to pull, but ignore failures.
  docker-compose pull --ignore-pull-failures
  docker-compose build --build-arg RUBY_VERSION="$RUBY_VERSION"
  docker-compose up -d pg conjur_4 conjur_5
}

function runTests_5() {
  echo 'Waiting for Conjur v5 to come up, and configuring it...'
  ./ci/configure_v5.sh

  local api_key=$(docker-compose exec -T conjur_5 rake 'role:retrieve-key[cucumber:user:admin]')

  echo 'Running tests'
  echo '-----'
  docker-compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    tester_5 rake jenkins_init jenkins_spec jenkins_cucumber_v5
}

function runTests_4() {
  echo 'Waiting for Conjur v4 to come up, and configuring it...'
  ./ci/configure_v4.sh

  local api_key=$(docker-compose exec -T conjur_4 su conjur -c "conjur-plugin-service authn env RAILS_ENV=appliance rails r \"puts User['admin'].api_key\" 2>/dev/null")

  echo 'Running tests'
  echo '-----'
  docker-compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    tester_4 rake jenkins_cucumber_v4
}

main
