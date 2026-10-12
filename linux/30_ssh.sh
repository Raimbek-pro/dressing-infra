#!/usr/bin/env bash
# Task 4: SSH key-only access, root login off, automation_bot reachable by key.
# Run as root on BOTH VMs:  sudo ./30_ssh.sh "<contents of automation_bot.pub>"
# Generate the key pair on YOUR laptop first (private key never leaves it):
#   ssh-keygen -t ed25519 -C automation_bot -f ~/.ssh/dressing_automation_bot
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root"; exit 1; }
PUBKEY="${1:?pass the automation_bot public key}"
[[ "$PUBKEY" == ssh-ed25519\ * ]] || { echo "expected an ssh-ed25519 public key"; exit 1; }

auth=/home/automation_bot/.ssh/authorized_keys
grep -qxF "$PUBKEY" "$auth" 2>/dev/null || echo "$PUBKEY" >>"$auth"
chown automation_bot:automation "$auth"
chmod 0600 "$auth"

# Drop-in config: Debian's sshd_config includes /etc/ssh/sshd_config.d/*.conf first.
cat >/etc/ssh/sshd_config.d/10-dressing.conf <<'EOF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
X11Forwarding no
# Only these groups may log in at all; service accounts (dressing, postgres) never can.
# google-sudoers keeps the GCP console "SSH" button working for the project admin.
AllowGroups sysadmins devops developers dba auditors automation google-sudoers
EOF

sshd -t                      # validate before reload so we can't lock ourselves out
systemctl reload ssh
sshd -T | grep -Ei '^(permitrootlogin|passwordauthentication|allowgroups|maxauthtries)'
