#!/bin/bash
# Task 4: SSH key login for automation_bot
# Usage: sudo linux/30_ssh.sh "ssh-ed25519 AAAA... automation_bot"
set -e
KEY="$1"

mkdir -p /home/automation_bot/.ssh
grep -qxF "$KEY" /home/automation_bot/.ssh/authorized_keys 2>/dev/null || echo "$KEY" >> /home/automation_bot/.ssh/authorized_keys
chown -R automation_bot:automation /home/automation_bot/.ssh
chmod 700 /home/automation_bot/.ssh
chmod 600 /home/automation_bot/.ssh/authorized_keys

cat > /etc/ssh/sshd_config.d/10-dressing.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowGroups sysadmins devops developers dba auditors automation google-sudoers
EOF

sshd -t
systemctl reload ssh
sshd -T | grep -Ei '^(permitrootlogin|passwordauthentication|allowgroups)'
