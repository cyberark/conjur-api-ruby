#!/bin/bash -e

: "${RUBY_VERSION=2.7}"
# My local RUBY_VERSION is set to ruby-#.#.# so this allows running locally.
RUBY_VERSION="$(cut -d '-' -f 2 <<< "$RUBY_VERSION")"
export TAG="$RUBY_VERSION-$(git rev-parse --short=8 HEAD)"

function finish {
  echo 'Removing test environment'
  echo '---'
  docker-compose down --rmi 'local' --volumes
  docker rmi "tester:$TAG"
}

trap finish EXIT


function main() {
  # Generate reports folders locally
  rm -rf "test_$RUBY_VERSION"
  docker build --build-arg RUBY_VERSION="$RUBY_VERSION" --tag="tester:$TAG" .
  mkdir "test_$RUBY_VERSION"
  cp docker-compose.yml "./test_$RUBY_VERSION/"
  cd "test_$RUBY_VERSION"
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
  docker-compose up -d pg conjur_4 conjur_5
}

function runTests_5() {
  echo 'Waiting for Conjur v5 to come up, and configuring it...'
  ../ci/configure_v5.sh

  local api_key=$(docker-compose exec -T conjur_5 rake 'role:retrieve-key[cucumber:user:admin]')

  echo 'Running tests'
  echo '-----'
  docker-compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    tester_5 rake jenkins_init jenkins_spec jenkins_cucumber_v5
}

function runTests_4() {
  echo 'Waiting for Conjur v4 to come up, and configuring it...'
  ../ci/configure_v4.sh

  local api_key=$(docker-compose exec -T conjur_4 su conjur -c "conjur-plugin-service authn env RAILS_ENV=appliance rails r \"puts User['admin'].api_key\" 2>/dev/null")

  echo 'Running tests'
  echo '-----'
  docker-compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    tester_4 rake jenkins_cucumber_v4
}

main
