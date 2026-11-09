#!/usr/bin/env bash
# YOUR SCRIPT. It must bring the whole Pollie stack up from nothing, and be safe to run again.
# Names are fixed (verify.sh depends on them):
#   networks   pw-frontend  pw-backend
#   volume     pw-pgdata
#   containers pw-db  pw-redis  pw-api  pw-worker  pw-web
# The image for the api and the worker is pollie:lab3 (built by ./setup.sh), the settings are in lab.env.
set -euo pipefail
cd "$(dirname "$0")"

echo "TODO: write me"
exit 1
