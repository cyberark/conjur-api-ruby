#!/bin/bash -e

: "${RUBY_VERSION=3.3}"
# My local RUBY_VERSION is set to ruby-#.#.# so this allows running locally.
RUBY_VERSION="$(cut -d '-' -f 2 <<< "$RUBY_VERSION")"

export REGISTRY_URL=${INFRAPOOL_REGISTRY_URL:-"docker.io"}
export RUBY_VERSION="${INFRAPOOL_RUBY_VERSION:-$RUBY_VERSION}"

# Cloud-authenticator integration toggles. These accept both plain and
# INFRAPOOL_-prefixed variants (Jenkins injects the latter). When any is
# "true", ONLY that authenticator's tagged feature runs against real cloud
# infrastructure; the normal suite is skipped. Left unset by default so PR
# builds run the ordinary unit + cucumber suite.
RUN_AWS_TESTS="${INFRAPOOL_RUN_AWS_TESTS:-${RUN_AWS_TESTS:-false}}"
RUN_AZURE_TESTS="${INFRAPOOL_RUN_AZURE_TESTS:-${RUN_AZURE_TESTS:-false}}"
RUN_GCP_TESTS="${INFRAPOOL_RUN_GCP_TESTS:-${RUN_GCP_TESTS:-false}}"
export RUN_AWS_TESTS RUN_AZURE_TESTS RUN_GCP_TESTS

# authn-iam identifies the Conjur host by the AWS caller identity; the AWS stage
# derives these from `aws sts get-caller-identity` on the agent.
AWS_ACCOUNT_ID="${INFRAPOOL_AWS_ACCOUNT_ID:-${AWS_ACCOUNT_ID:-}}"
AWS_ROLE_NAME="${INFRAPOOL_AWS_ROLE_NAME:-${AWS_ROLE_NAME:-}}"
export AWS_ACCOUNT_ID AWS_ROLE_NAME

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

# Returns the cloud-authn cucumber tag to run when a RUN_*_TESTS flag is set,
# or empty for a normal run. Validates required env vars for the chosen cloud.
function cloudAuthnTag() {
  if [[ "$RUN_AWS_TESTS" == "true" ]]; then
    : "${AWS_ACCOUNT_ID:?AWS_ACCOUNT_ID is required for IAM tests (derived from aws sts get-caller-identity)}"
    : "${AWS_ROLE_NAME:?AWS_ROLE_NAME is required for IAM tests (derived from aws sts get-caller-identity)}"
    echo '@authn_iam'
  elif [[ "$RUN_AZURE_TESTS" == "true" ]]; then
    : "${AZURE_SUBSCRIPTION_ID:?AZURE_SUBSCRIPTION_ID is required for Azure tests}"
    : "${AZURE_RESOURCE_GROUP:?AZURE_RESOURCE_GROUP is required for Azure tests}"
    echo '@authn_azure'
  elif [[ "$RUN_GCP_TESTS" == "true" ]]; then
    : "${GCP_ID_TOKEN:?GCP_ID_TOKEN is required for GCP tests (run ci/get_gcp_token.sh first)}"
    echo '@authn_gcp'
  fi
}

function main() {
  if ! docker info >/dev/null 2>&1; then
    echo "Docker does not seem to be running, run it first and retry"
    exit 1
  fi
  # Generate reports folders locally
  mkdir -p spec/reports features/reports

  CLOUD_AUTHN_TAG="$(cloudAuthnTag)"

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

  local api_key=$(docker compose exec -T conjur conjurctl role retrieve-key cucumber:user:admin | tr -d '\r\n')

  if [[ -n "$CLOUD_AUTHN_TAG" ]]; then
    runCloudAuthnTests "$api_key"
  else
    runDefaultTests "$api_key"
  fi
}

function runDefaultTests() {
  local api_key="$1"
  echo 'Running tests'
  echo '-----'
  docker compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    -e SSL_CERT_FILE=/etc/ssl/certs/keycloak.pem \
    tester \
    "/scripts/fetch_certificate && bundle exec rake jenkins_init jenkins_spec jenkins_cucumber"
}

# Runs a single cloud-authenticator feature against real cloud infrastructure.
# Forwards the cloud provider env vars and clears proxies so the container can
# reach the link-local metadata endpoints (169.254.169.254, metadata.google.internal).
function runCloudAuthnTests() {
  local api_key="$1"
  echo "Running cloud authenticator tests: $CLOUD_AUTHN_TAG"
  echo '-----'
  local rc=0
  docker compose run --rm \
    -e CONJUR_AUTHN_API_KEY="$api_key" \
    -e CLOUD_AUTHN_TAG="$CLOUD_AUTHN_TAG" \
    -e NO_PROXY="169.254.169.254,metadata.google.internal,localhost,127.0.0.1,conjur" \
    -e HTTP_PROXY="" -e HTTPS_PROXY="" -e http_proxy="" -e https_proxy="" \
    -e AZURE_SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-}" \
    -e AZURE_RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-}" \
    -e USER_ASSIGNED_IDENTITY_CLIENT_ID="${USER_ASSIGNED_IDENTITY_CLIENT_ID:-}" \
    -e GCP_ID_TOKEN="${GCP_ID_TOKEN:-}" \
    -e GCP_PROJECT_ID="${GCP_PROJECT_ID:-}" \
    -e AWS_ACCOUNT_ID="${AWS_ACCOUNT_ID:-}" \
    -e AWS_ROLE_NAME="${AWS_ROLE_NAME:-}" \
    tester \
    "bundle exec rake jenkins_init jenkins_cucumber_cloud" || rc=$?

  # On failure, dump the Conjur server log: authn-azure/iam/gcp rejections are
  # logged there with the precise reason (issuer/annotation/audience mismatch),
  # which the client only ever sees as an opaque 401.
  if [[ $rc -ne 0 ]]; then
    echo "=== cloud authn test failed; last 100 lines of Conjur server log ==="
    docker compose logs --tail=100 conjur || true
    echo '=== end Conjur server log ==='
  fi
  return $rc
}

main