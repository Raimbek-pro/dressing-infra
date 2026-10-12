# dressing-infra

Linux infrastructure for the Dressing iOS app on Google Cloud: SIS #2 "Users and permissions".

```
iPhone app ──HTTPS──▶ dressing-app (public, 10.10.0.10)        dressing-db (private, 10.10.0.20)
                      nginx :80/443 → dressing-api :8080 ──5432/TLS──▶ PostgreSQL 17
                      (users: www-data, dressing)                    (user: postgres)
you ──SSH key──▶ dressing-app ──ProxyJump──▶ dressing-db   (db has no public IP; apt via Cloud NAT)
```

## Run order

| # | Where | Command | SIS2 task |
|---|-------|---------|-----------|
| 1 | Cloud Shell | `gcp/01_create_infra.sh <your-ip>/32` | infrastructure |
| 2 | both VMs | `sudo linux/10_users_groups.sh` | 2: groups and users |
| 3 | both VMs | `sudo linux/20_permissions.sh` | 3: file permissions, sudoers |
| 4 | db VM | `sudo db/40_postgres.sh 10.10.0.10`, copy the printed `DATABASE_URL` line | database |
| 5 | app VM | paste it into `/etc/dressing/dressing.env`, then `sudo app/50_app.sh` | 5: systemd unit |
| 6 | laptop | `ssh-keygen -t ed25519 -C automation_bot -f ~/.ssh/dressing_automation_bot` | 4: SSH |
| 7 | both VMs | `sudo linux/30_ssh.sh "<contents of dressing_automation_bot.pub>"` | 4: SSH |

The role table (task 1) is in the report.

Copy the repo to a VM with `gcloud compute scp --recurse . dressing-app:~/dressing-infra` (add `--tunnel-through-iap` for dressing-db).

## SSH as automation_bot (laptop `~/.ssh/config`)

```
Host dressing-app
    HostName <app external IP>
    User automation_bot
    IdentityFile ~/.ssh/dressing_automation_bot
    IdentitiesOnly yes

Host dressing-db
    HostName 10.10.0.20
    User automation_bot
    IdentityFile ~/.ssh/dressing_automation_bot
    IdentitiesOnly yes
    ProxyJump dressing-app
```

Check: `ssh dressing-app 'sudo -l'` lists only the dressing-api service commands.

## Verify

```
curl http://<app external IP>/health          # {"status": "ok", "db": "ok"}
sudo reboot   # on dressing-app; after it comes back, /health answers again (systemd unit enabled)
```
