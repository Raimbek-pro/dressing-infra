#!/usr/bin/env bash
# Task 5 on dressing-app: install nginx, package the API as a release, deploy it,
# and register it as a systemd unit that starts at every boot.
# Prerequisite: /etc/dressing/dressing.env contains the DATABASE_URL line printed by 40_postgres.sh.
# Run as root:  sudo ./50_app.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"

grep -q '^DATABASE_URL=' /etc/dressing/dressing.env || { echo "put DATABASE_URL into /etc/dressing/dressing.env first"; exit 1; }

apt-get update
apt-get install -y nginx python3-psycopg postgresql-client

# Release archive -> /srv/releases -> dressing-deploy (the same path CI will use).
release="dressing-api-$(date +%Y%m%d%H%M%S).tar.gz"
tar -czf "/srv/releases/$release" -C "$HERE" dressing_api.py
chgrp devops "/srv/releases/$release"

install -m 0644 -o root -g root "$HERE/dressing-api.service" /etc/systemd/system/dressing-api.service
systemctl daemon-reload
systemctl enable dressing-api          # start at every boot
/usr/local/bin/dressing-deploy "$release"

install -m 0644 "$HERE/nginx-dressing.conf" /etc/nginx/sites-available/dressing
ln -sfn /etc/nginx/sites-available/dressing /etc/nginx/sites-enabled/dressing
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

systemctl --no-pager status dressing-api | head -5
curl -s http://127.0.0.1/health; echo
