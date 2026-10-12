#!/usr/bin/env bash
# Task 3: file permissions + sudoers for every group.
# Run as root on BOTH VMs:  sudo linux/20_permissions.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"

# --- directories ------------------------------------------------------------------
#  path                 owner:group          mode  why
#  /opt/dressing        root:dressing        0750  code: service can read/run it, not modify it
#  /etc/dressing        root:dressing        0750  config + secrets
#  /var/lib/dressing    dressing:dressing    0750  the only place the service may write
install -d -m 0750 -o root     -g dressing /opt/dressing /etc/dressing
install -d -m 0750 -o dressing -g dressing /var/lib/dressing

# Secrets file: root writes it, the service reads it, nobody else sees it.
touch /etc/dressing/dressing.env
chown root:dressing /etc/dressing/dressing.env
chmod 0640 /etc/dressing/dressing.env

# --- sudoers: never edit /etc/sudoers itself, drop a file in sudoers.d ------------------
tmp="$(mktemp)"
cp "$HERE/sudoers.d/10-dressing" "$tmp"
visudo -cf "$tmp"                                  # refuse to install a broken policy
install -m 0440 -o root -g root "$tmp" /etc/sudoers.d/10-dressing
rm -f "$tmp"
touch /var/log/sudo.log && chmod 0600 /var/log/sudo.log

echo "== directories"; ls -ld /opt/dressing /etc/dressing /etc/dressing/dressing.env /var/lib/dressing
echo "== effective sudo rules";  for u in sysadmin1 devops1 developer1 dba1 auditor1 automation_bot; do echo "--- $u"; sudo -l -U "$u" | sed -n '/may run/,$p'; done
