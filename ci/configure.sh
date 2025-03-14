#!/bin/bash -e

source ./ci/oauth/keycloak/keycloak_functions.sh

cat << "CONFIGURE" | docker exec -i $(docker compose ps -q conjur) bash
set -e

for _ in $(seq 20); do
  curl -o /dev/null -fs -X OPTIONS http://localhost > /dev/null && break
  echo .
  sleep 2
done

# So we fail if the server isn't up yet:
curl -o /dev/null -fs -X OPTIONS http://localhost > /dev/null
CONFIGURE

wait_for_keycloak_server

fetch_keycloak_certificate
create_keycloak_users
