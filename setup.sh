#!/usr/bin/env bash
# Prepares the lab: gets the Pollie source and builds the image you will run. Run:  ./setup.sh   (no sudo)
set -uo pipefail
cd "$(dirname "$0")"
command -v docker >/dev/null || { echo "docker is not installed or not on PATH"; exit 1; }
command -v git >/dev/null || { echo "git is not installed"; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker is not running (or your user may not use it). Start Docker and try again."; exit 1; }
if [ -d pollie ] && docker image inspect pollie:lab3 >/dev/null 2>&1; then echo "The lab is already set up. Run ./teardown.sh first to start over."; exit 1; fi
if (exec 3<>/dev/tcp/127.0.0.1/8080) 2>/dev/null; then echo "Port 8080 is in use on your machine. Free it first."; exit 1; fi
[ -d pollie/.git ] || { echo "Getting the Pollie source (v0.1.1)..."; git clone -q --depth 1 --branch v0.1.1 https://github.com/professordiogodev/pollie.git pollie 2>/dev/null || { echo "could not clone Pollie (network?)"; exit 1; }; }
echo "Pulling images (first run only)..."
for img in python:3.12-slim postgres:16-alpine redis:7-alpine nginx:alpine; do docker pull -q "$img" >/dev/null || { echo "could not pull $img"; exit 1; }; done
echo "Building pollie:lab3 (the image for the API and the worker)..."
docker build -q --label lab=docker-pollie-by-hand -f base/Dockerfile -t pollie:lab3 pollie >/dev/null || { echo "build failed"; exit 1; }
echo
echo "Ready. You have:"
echo "  pollie:lab3  the Pollie image (API and worker; the worker starts with: python -m pollie.worker)"
echo "  pollie/web   the static web app, to be served by Nginx"
echo "  nginx.conf   the Nginx config, to mount into the web container"
echo "  lab.env      settings for the Pollie containers"
echo "  stack.sh     the script YOU will write"
