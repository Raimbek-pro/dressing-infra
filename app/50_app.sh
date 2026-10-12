#!/usr/bin/env bash
# Task 5 on dressing-app: install the backend as a systemd unit that starts at every boot,
# with nginx in front of it.
# Prerequisite: /etc/dressing/dressing.env contains the DATABASE_URL line printed by 40_postgres.sh.
# Run as root:  sudo app/50_app.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"

grep -q '^DATABASE_URL=' /etc/dressing/dressing.env || { echo "put DATABASE_URL into /etc/dressing/dressing.env first"; exit 1; }

apt-get update
apt-get install -y nginx python3-psycopg

# The program: owned by root, readable by the dressing group, so the service can't modify it.
install -m 0640 -o root -g dressing "$HERE/dressing_api.py" /opt/dressing/dressing_api.py

# The systemd unit.
install -m 0644 -o root -g root "$HERE/dressing-api.service" /etc/systemd/system/dressing-api.service
systemctl daemon-reload
systemctl enable dressing-api          # start at every boot
systemctl restart dressing-api         # start (or restart) it now

# nginx: our site on, default welcome site off.
install -m 0644 "$HERE/nginx-dressing.conf" /etc/nginx/sites-available/dressing
ln -sfn /etc/nginx/sites-available/dressing /etc/nginx/sites-enabled/dressing
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx
sleep 1                                 # let nginx and the service finish starting

systemctl --no-pager status dressing-api | head -5
curl -s http://127.0.0.1/health; echo
