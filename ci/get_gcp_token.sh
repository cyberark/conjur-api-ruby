#!/bin/bash -e
#
# Fetch a GCP identity token from the instance metadata service.
#
# This is meant to run ON a GCP executor agent. GCP agents typically lack a
# Docker runtime, so the authn-jwt/gcp integration test itself runs on a
# different (e.g. AWS) agent. This script fetches a real identity token here,
# writes it to a file, and the Jenkins pipeline stashes it and hands it to the
# test container via the GCP_ID_TOKEN env var.
#
# Usage: ./ci/get_gcp_token.sh <host-id> <account> <output-dir>
#   host-id     Conjur host id WITHOUT the "host/" prefix
#               (e.g. "data/test/gcp-apps/test-app")
#   account     Conjur account (e.g. "cucumber")
#   output-dir  directory to write "token" and "project-id" into

HOST_ID="${1:?host-id (without host/ prefix) is required}"
ACCOUNT="${2:?account is required}"
OUT_DIR="${3:?output directory is required}"

METADATA_BASE="http://metadata.google.internal/computeMetadata/v1"
AUDIENCE="conjur/${ACCOUNT}/host/${HOST_ID}"

mkdir -p "${OUT_DIR}"

echo "Fetching GCP identity token for audience: ${AUDIENCE}"
token="$(curl -sS --noproxy '*' -H 'Metadata-Flavor: Google' \
  "${METADATA_BASE}/instance/service-accounts/default/identity?audience=${AUDIENCE}&format=full")"

# Sanity-check that we got a 3-part JWT rather than an HTML error page.
if [[ "$(grep -o '\.' <<< "${token}" | wc -l | tr -d ' ')" != "2" ]]; then
  echo "ERROR: metadata service did not return a JWT. Got:" >&2
  echo "${token}" >&2
  exit 1
fi

project_id="$(curl -sS --noproxy '*' -H 'Metadata-Flavor: Google' \
  "${METADATA_BASE}/project/project-id")"

printf '%s' "${token}"      > "${OUT_DIR}/token"
printf '%s' "${project_id}" > "${OUT_DIR}/project-id"

echo "Wrote ${OUT_DIR}/token and ${OUT_DIR}/project-id"
