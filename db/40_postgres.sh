#!/bin/bash
# Database: install PostgreSQL, allow only the app VM, create roles and tables
# Usage: sudo db/40_postgres.sh 10.10.0.10
set -e
cd "$(dirname "$0")"
APP_IP="$1"
DB_IP="$(hostname -I | awk '{print $1}')"

apt-get update
apt-get install -y postgresql
CONF="/etc/postgresql/$(ls /etc/postgresql | tail -1)/main"

sed "s/localhost'/localhost,$DB_IP'/" postgresql.d/10-dressing.conf > "$CONF/conf.d/10-dressing.conf"
sed "s/APP_IP/$APP_IP/" pg_hba.conf > "$CONF/pg_hba.conf"
systemctl restart postgresql

[ -f /root/dressing-db.secret ] || echo "DATABASE_URL=postgresql://dressing_app:$(openssl rand -hex 16)@$DB_IP:5432/dressing?sslmode=require" > /root/dressing-db.secret
chmod 600 /root/dressing-db.secret
PASSWORD="$(sed 's/.*dressing_app:\([^@]*\)@.*/\1/' /root/dressing-db.secret)"

sudo -u postgres psql -v ON_ERROR_STOP=1 -v app_pw="$PASSWORD" < roles.sql
sudo -u postgres psql -v ON_ERROR_STOP=1 -d dressing < schema.sql

sudo -u postgres psql -c '\du'
cat /root/dressing-db.secret
