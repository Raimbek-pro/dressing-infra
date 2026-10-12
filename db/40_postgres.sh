#!/usr/bin/env bash
# PostgreSQL on dressing-db (Debian 13 ships PostgreSQL 17).
# Run as root on the DB VM:  sudo ./40_postgres.sh 10.10.0.10
# Arg: private IP of the app VM, the only host allowed to connect over the network.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
APP_IP="${1:?private IP of dressing-app}"
HERE="$(cd "$(dirname "$0")" && pwd)"

apt-get update
apt-get install -y postgresql
PG_VER="$(ls /etc/postgresql | sort -V | tail -1)"
CONF="/etc/postgresql/$PG_VER/main"
DB_IP="$(hostname -I | awk '{print $1}')"

# Our settings live in conf.d so package upgrades never conflict with them.
install -m 0644 -o postgres -g postgres "$HERE/postgresql.d/10-dressing.conf" "$CONF/conf.d/10-dressing.conf"
sed -i "s|^listen_addresses.*|listen_addresses = 'localhost,$DB_IP'|" "$CONF/conf.d/10-dressing.conf"

# pg_hba.conf: replaced entirely, first matching line wins.
sed "s|APP_IP|$APP_IP|g" "$HERE/pg_hba.conf" >"$CONF/pg_hba.conf"
chown postgres:postgres "$CONF/pg_hba.conf"
chmod 0640 "$CONF/pg_hba.conf"

systemctl restart postgresql
systemctl enable postgresql

# Roles and database. Password generated here, shown once, stored root-only.
SECRET=/root/dressing-db.secret
if [[ ! -f "$SECRET" ]]; then
    umask 077
    printf 'DATABASE_URL=postgresql://dressing_app:%s@%s:5432/dressing?sslmode=require\n' \
        "$(openssl rand -base64 30 | tr -dc 'A-Za-z0-9' | head -c 32)" "$DB_IP" >"$SECRET"
fi
APP_PW="$(sed -E 's|.*dressing_app:([^@]+)@.*|\1|' "$SECRET")"

sudo -u postgres psql -v ON_ERROR_STOP=1 -v app_pw="$APP_PW" -f "$HERE/roles.sql"
sudo -u postgres psql -v ON_ERROR_STOP=1 -d dressing -f "$HERE/schema.sql"

echo "== listening";  ss -ltnp | grep 5432
echo "== roles";      sudo -u postgres psql -c '\du'
echo "Copy this line into /etc/dressing/dressing.env on dressing-app (root:dressing 0640):"
cat "$SECRET"
