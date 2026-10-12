#!/bin/bash
# Task 5: the backend as a systemd service, with nginx in front
set -e
cd "$(dirname "$0")"

apt-get update
apt-get install -y nginx python3-psycopg

install -m 640 -o root -g dressing dressing_api.py /opt/dressing/dressing_api.py
install -m 644 dressing-api.service /etc/systemd/system/dressing-api.service
systemctl daemon-reload
systemctl enable dressing-api
systemctl restart dressing-api

install -m 644 nginx-dressing.conf /etc/nginx/sites-available/dressing
ln -sf /etc/nginx/sites-available/dressing /etc/nginx/sites-enabled/dressing
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx
sleep 1

systemctl status dressing-api --no-pager | head -5
curl -s http://127.0.0.1/health; echo
