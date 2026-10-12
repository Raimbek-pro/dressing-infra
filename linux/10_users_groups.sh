#!/usr/bin/env bash
# Task 2: create every group from the role table and at least one user per role.
# Run as root on BOTH VMs:  sudo ./10_users_groups.sh
# Idempotent: re-running skips what already exists.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }

# --- human / automation groups ------------------------------------------------
GROUPS_HUMAN=(sysadmins devops developers dba auditors automation)
for g in "${GROUPS_HUMAN[@]}"; do
    getent group "$g" >/dev/null || groupadd "$g"
done

# --- service accounts (no login, no password, no home in /home) ---------------
# 'dressing' runs the backend API. 'postgres' and 'www-data' are created by the
# postgresql and nginx packages themselves; we only document them in the role table.
if ! id dressing &>/dev/null; then
    useradd --system --user-group --home-dir /var/lib/dressing --create-home \
            --shell /usr/sbin/nologin --comment "Dressing backend service" dressing
fi

# --- one human user per role ---------------------------------------------------
# name            primary  extra groups                 comment
USERS=(
  "sysadmin1      sysadmins  adm                          System administrator"
  "devops1        devops     developers                   DevOps engineer (deploys)"
  "developer1     developers ''                           Backend developer"
  "dba1           dba        ''                           Database administrator"
  "auditor1       auditors   systemd-journal,adm          Security auditor (read-only)"
  "automation_bot automation devops                       CI/CD + Ansible, SSH key only"
)
for row in "${USERS[@]}"; do
    read -r name primary extra comment <<<"$row"
    extra="${extra//\'/}"
    if ! id "$name" &>/dev/null; then
        useradd --create-home --shell /bin/bash --gid "$primary" \
                ${extra:+--groups "$extra"} --comment "$comment" "$name"
        # No usable password yet: humans set one on first login via `passwd`
        # after the admin runs `passwd -e`; the bot never gets one (key only).
        passwd -l "$name" >/dev/null
    fi
    install -d -m 700 -o "$name" -g "$primary" "/home/$name/.ssh"
done

# Home directories private to their owner (Debian default is 0755).
chmod 0750 /home/*/

echo "== groups";  getent group "${GROUPS_HUMAN[@]}" dressing
echo "== users";   for u in sysadmin1 devops1 developer1 dba1 auditor1 automation_bot dressing; do id "$u"; done
