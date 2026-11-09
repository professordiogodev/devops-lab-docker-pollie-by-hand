#!/usr/bin/env bash
# Run with: ./verify.sh   (it runs YOUR stack.sh, then tests the result, then destroys and rebuilds the containers to test persistence)
set -u
cd "$(dirname "$0")"
docker info >/dev/null 2>&1 || { echo "Docker is not running"; exit 1; }
[ -d pollie ] && docker image inspect pollie:lab3 >/dev/null 2>&1 || { echo "Run ./setup.sh first"; exit 1; }
pass=0; failn=0; total=0
check() { local d="$1"; shift; total=$((total+1)); if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
insp() { docker inspect -f "$1" "$2" 2>/dev/null; }
nets() { docker inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{println $k}}{{end}}' "$1" 2>/dev/null | grep . | sort | tr '\n' ' '; }
API=http://127.0.0.1:8080/api

echo "== Your stack.sh =="
check "stack.sh exists and is executable" test -x stack.sh
if ! ./stack.sh >/tmp/pw-stack.log 2>&1; then echo "FAIL  stack.sh runs without errors (output below)"; tail -15 /tmp/pw-stack.log; echo; echo "Fix stack.sh and run ./verify.sh again."; exit 1; fi
echo "PASS  stack.sh runs without errors"; pass=$((pass+1)); total=$((total+1))
check "stack.sh can be run a second time (idempotent)" bash -c "./stack.sh"
sleep 6

echo "== Topology =="
for c in pw-db pw-redis pw-api pw-worker pw-web; do check "$c is running" test "$(insp '{{.State.Running}}' $c)" = true; done
check "pw-db is only on pw-backend" test "$(nets pw-db)" = "pw-backend "
check "pw-web is only on pw-frontend" test "$(nets pw-web)" = "pw-frontend "
check "pw-api is on both networks (the bridge between them)" test "$(nets pw-api)" = "pw-backend pw-frontend "
check "pw-worker and pw-redis are on pw-backend only" bash -c "[ \"$(nets pw-worker)\" = 'pw-backend ' ] && [ \"$(nets pw-redis)\" = 'pw-backend ' ]"
check "only the web container publishes a port, and only on 127.0.0.1" bash -c "[ -z \"\$(docker port pw-db)\$(docker port pw-api)\$(docker port pw-redis)\$(docker port pw-worker)\" ] && docker port pw-web | grep -q '^80/tcp -> 127.0.0.1:8080'"
check "the database data lives in the named volume pw-pgdata" bash -c "docker inspect -f '{{range .Mounts}}{{.Name}}:{{.Destination}}{{println}}{{end}}' pw-db | grep -q '^pw-pgdata:/var/lib/postgresql/data\$'"
check "the web container mounts nginx.conf and the web files read-only" bash -c "docker inspect -f '{{range .Mounts}}{{.Destination}}:{{.RW}}{{println}}{{end}}' pw-web | grep -q '^/etc/nginx/conf.d/default.conf:false' && docker inspect -f '{{range .Mounts}}{{.Destination}}:{{.RW}}{{println}}{{end}}' pw-web | grep -q '^/usr/share/nginx/html:false'"
check "every container restarts unless stopped" bash -c "for c in pw-db pw-redis pw-api pw-worker pw-web; do [ \"\$(docker inspect -f '{{.HostConfig.RestartPolicy.Name}}' \$c)\" = unless-stopped ] || exit 1; done"

echo "== Isolation =="
check "the API can reach the database (pw-db:5432)" docker exec pw-api python -c "import socket; socket.create_connection(('pw-db',5432),2)"
check "the API can reach Redis (pw-redis:6379)" docker exec pw-api python -c "import socket; socket.create_connection(('pw-redis',6379),2)"
check "the web container CANNOT resolve or reach the database" bash -c "! docker exec pw-web nc -z -w 2 pw-db 5432"
check "the web container CANNOT reach Redis" bash -c "! docker exec pw-web nc -z -w 2 pw-redis 6379"

echo "== It works =="
check "http://localhost:8080 serves the Pollie web app" bash -c "curl -s --max-time 5 http://127.0.0.1:8080/ | grep -qi 'pollie'"
check "/api/readyz through Nginx says ready (database and Redis reachable from the API)" bash -c "for i in \$(seq 20); do curl -sf --max-time 3 $API/readyz && exit 0; sleep 1; done; exit 1"
e2e() {
  local p pid oid body code
  p=$(curl -s --max-time 5 -XPOST "$API/polls" -H 'Content-Type: application/json' -d '{"question":"Persisted?","options":["yes","no"]}')
  pid=$(sed -E 's/^\{"id":([0-9]+).*/\1/' <<<"$p"); oid=$(grep -oE '"options":\[\{"id":[0-9]+' <<<"$p" | grep -oE '[0-9]+$')
  [ -n "$pid" ] && [ -n "$oid" ] || return 1
  echo "$pid" > /tmp/pw-poll-id
  body=$(printf '{"option_id":%s,"voter_id":"v1"}' "$oid")
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 -XPOST "$API/polls/$pid/votes" -H 'Content-Type: application/json' -d "$body")
  [ "$code" = 202 ] || return 1
  for _ in $(seq 20); do sleep 1; curl -s --max-time 5 "$API/polls/$pid/results" | grep -q '"total_votes":1' && return 0; done
  return 1
}
check "end to end through the browser path: poll, vote, the worker records it" e2e

echo "== Persistence =="
pid=$(cat /tmp/pw-poll-id 2>/dev/null || echo 0)
docker rm -f pw-web pw-api pw-worker pw-redis pw-db >/dev/null 2>&1
check "all containers are gone (the volume is not)" bash -c "[ -z \"\$(docker ps -a --format '{{.Names}}' | grep -E '^pw-')\" ] && docker volume inspect pw-pgdata"
check "stack.sh brings everything back from nothing" ./stack.sh
check "the poll created before the containers were destroyed is still there" bash -c "for i in \$(seq 25); do curl -sf --max-time 3 $API/polls/$pid | grep -q 'Persisted?' && exit 0; sleep 1; done; exit 1"

echo "== Backup =="
check "backup.sql is a real pg_dump of the pollie database (tables and data)" bash -c "grep -q 'CREATE TABLE public.polls' backup.sql && grep -q 'Persisted?' backup.sql"

echo
if [ "$failn" -eq 0 ]; then echo "ALL CHECKS PASSED ($pass/$total)"; else echo "$failn check(s) failed, $pass passed"; fi
exit "$failn"
