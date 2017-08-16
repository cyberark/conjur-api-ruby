#!/bin/bash -e

for _ in $(seq 20); do
  curl -o /dev/null -fs -X OPTIONS http://conjur > /dev/null && break
  echo .
  sleep 2
done

# So we fail if the server isn't up yet:
curl -o /dev/null -fs -X OPTIONS http://conjur > /dev/null
