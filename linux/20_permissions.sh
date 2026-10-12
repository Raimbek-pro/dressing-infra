#!/usr/bin/env bash
# Task 3: file permissions + sudoers. Run as root on BOTH VMs: sudo linux/20_permissions.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"

# Code and config: root owns them, the dressing service can only read them.
install -d -m 0750 -o root -g dressing /opt/dressing /etc/dressing
touch /etc/dressing/dressing.env
chown root:dressing /etc/dressing/dressing.env
chmod 0640 /etc/dressing/dressing.env          # database password: root writes, service reads

# Sudo rules: check with visudo first, then install into sudoers.d (never edit /etc/sudoers).
visudo -cf "$HERE/sudoers.d/10-dressing"
install -m 0440 -o root -g root "$HERE/sudoers.d/10-dressing" /etc/sudoers.d/10-dressing

ls -ld /opt/dressing /etc/dressing /etc/dressing/dressing.env
for u in sysadmin1 devops1 developer1 dba1 auditor1 automation_bot; do echo "--- $u"; sudo -l -U "$u" | sed -n '/may run/,$p'; done
