#!/usr/bin/env bash
# Removes everything the lab created. Run:  ./teardown.sh
set -uo pipefail
cd "$(dirname "$0")"
ids=$(docker ps -a -q --filter label=lab=docker-pollie-by-hand)
names=$(docker ps -a --format '{{.Names}}' | grep -E '^pw-|^dns-' || true)
[ -n "$ids" ] && docker rm -f -v $ids >/dev/null
[ -n "$names" ] && docker rm -f -v $names >/dev/null
for n in pw-frontend pw-backend dns-net; do docker network rm "$n" >/dev/null 2>&1 || true; done
docker network ls -q --filter label=lab=docker-pollie-by-hand | xargs -r docker network rm >/dev/null 2>&1 || true
for v in pw-pgdata pw-pgdata-restored; do docker volume rm "$v" >/dev/null 2>&1 || true; done
docker volume ls -q --filter label=lab=docker-pollie-by-hand | xargs -r docker volume rm >/dev/null 2>&1 || true
docker rmi -f pollie:lab3 >/dev/null 2>&1 || true
docker images -q --filter label=lab=docker-pollie-by-hand | xargs -r docker rmi -f >/dev/null 2>&1 || true
rm -rf pollie
echo "Removed the containers, networks, volumes, the image and the cloned source. Now run ./verify-teardown.sh to prove it."
echo "(Your stack.sh, backup.sql and answers stay: they are your submission.)"
