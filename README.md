# dressing-infra

Linux infrastructure for the Dressing iOS app on Google Cloud: SIS #2 "Users and permissions".

```
iPhone app ──HTTPS──▶ dressing-app (public, 10.10.0.10)        dressing-db (private, 10.10.0.20)
                      nginx :80/443 → dressing-api :8080 ──5432/TLS──▶ PostgreSQL 17
                      (users: www-data, dressing)                    (user: postgres)
you ──SSH key──▶ dressing-app ──ProxyJump──▶ dressing-db   (db has no public IP; apt via Cloud NAT)
```

## Run order

| # | Where | Command |
|---|-------|---------|
| 1 | Cloud Shell | `gcp/01_create_infra.sh <your-ip>/32` |
| 2 | Cloud Shell | `gcp/02_project_iam.sh <admin> <devops> <auditor>` (optional, needs other Google accounts) |
| 3 | both VMs | `sudo linux/10_users_groups.sh` |
| 4 | both VMs | `sudo linux/20_permissions.sh` |
| 5 | laptop | `ssh-keygen -t ed25519 -C automation_bot -f ~/.ssh/dressing_automation_bot` |
| 6 | both VMs | `sudo linux/30_ssh.sh "$(cat ~/.ssh/dressing_automation_bot.pub)"` |
| 7 | db VM | `sudo db/40_postgres.sh 10.10.0.10` and copy the printed `DATABASE_URL` line |
| 8 | app VM | paste it into `/etc/dressing/dressing.env`, then `sudo app/50_app.sh` |

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

Check: `ssh dressing-db 'sudo -l'` lists only the app service and deploy commands.

## Verify

```
curl http://<app external IP>/health          # {"status": "ok", "db": "ok"}
sudo reboot   # on dressing-app; after it comes back, /health answers again (systemd unit enabled)
```
