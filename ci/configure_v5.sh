#!/bin/bash -e

cat << "CONFIGURE" | docker exec -i $(docker-compose ps -q conjur_5) bash
set -e

for _ in $(seq 100); do
  curl -o /dev/null -fs -X OPTIONS http://localhost > /dev/null && break
  echo -n .
  sleep 2
done

echo

# So we fail if the server isn't up yet:
curl -o /dev/null -fs -X OPTIONS http://localhost > /dev/null
CONFIGURE
