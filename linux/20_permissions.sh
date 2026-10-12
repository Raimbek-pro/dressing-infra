#!/bin/bash
# Task 3: file permissions and sudo rules
set -e
cd "$(dirname "$0")"

mkdir -p /opt/dressing /etc/dressing
chown root:dressing /opt/dressing /etc/dressing
chmod 750 /opt/dressing /etc/dressing

touch /etc/dressing/dressing.env
chown root:dressing /etc/dressing/dressing.env
chmod 640 /etc/dressing/dressing.env

visudo -cf sudoers.d/10-dressing
install -m 440 sudoers.d/10-dressing /etc/sudoers.d/10-dressing

ls -ld /opt/dressing /etc/dressing /etc/dressing/dressing.env
for u in sysadmin1 devops1 developer1 dba1 auditor1 automation_bot; do sudo -l -U "$u"; done
