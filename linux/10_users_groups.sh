#!/bin/bash
# Task 2: groups and users
set -e

groupadd -f sysadmins
groupadd -f devops
groupadd -f developers
groupadd -f dba
groupadd -f auditors
groupadd -f automation

id sysadmin1      &>/dev/null || useradd -m -s /bin/bash -g sysadmins  -G adm                 sysadmin1
id devops1        &>/dev/null || useradd -m -s /bin/bash -g devops     -G developers          devops1
id developer1     &>/dev/null || useradd -m -s /bin/bash -g developers                        developer1
id dba1           &>/dev/null || useradd -m -s /bin/bash -g dba                               dba1
id auditor1       &>/dev/null || useradd -m -s /bin/bash -g auditors   -G systemd-journal,adm auditor1
id automation_bot &>/dev/null || useradd -m -s /bin/bash -g automation -G devops              automation_bot

# service account for the backend: cannot log in
id dressing       &>/dev/null || useradd -r -U -s /usr/sbin/nologin dressing

chmod 750 /home/*/

getent group sysadmins devops developers dba auditors automation dressing
for u in sysadmin1 devops1 developer1 dba1 auditor1 automation_bot dressing; do id "$u"; done
