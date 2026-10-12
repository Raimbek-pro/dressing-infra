#!/usr/bin/env bash
# Creates the Dressing lab infrastructure in Google Cloud:
#   dressing-app  public VM: nginx + backend API (ports 80/443, SSH from your IP only)
#   dressing-db   private VM: PostgreSQL, no external IP, port 5432 open only to dressing-app
# Run from Cloud Shell or a machine with gcloud, after `gcloud config set project <PROJECT_ID>`.
# Usage: ./01_create_infra.sh <your-public-ip>/32
set -euo pipefail

MY_IP="${1:?usage: $0 <your-public-ip>/32}"
REGION="us-central1"
ZONE="us-central1-a"
NETWORK="dressing-vpc"
SUBNET="dressing-subnet"
PROJECT="$(gcloud config get-value project)"

echo "== APIs"
gcloud services enable compute.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com

echo "== Network: own VPC instead of 'default', so only the rules below exist"
gcloud compute networks create "$NETWORK" --subnet-mode=custom
gcloud compute networks subnets create "$SUBNET" --network="$NETWORK" --region="$REGION" \
    --range=10.10.0.0/24 --enable-private-ip-google-access

echo "== Firewall (deny by default; each rule opens one path)"
gcloud compute firewall-rules create dressing-allow-ssh-admin --network="$NETWORK" \
    --direction=INGRESS --action=ALLOW --rules=tcp:22 --source-ranges="$MY_IP" --target-tags=dressing-app
gcloud compute firewall-rules create dressing-allow-ssh-iap --network="$NETWORK" \
    --direction=INGRESS --action=ALLOW --rules=tcp:22 --source-ranges=35.235.240.0/20 --target-tags=dressing-app,dressing-db
gcloud compute firewall-rules create dressing-allow-web --network="$NETWORK" \
    --direction=INGRESS --action=ALLOW --rules=tcp:80,tcp:443 --source-ranges=0.0.0.0/0 --target-tags=dressing-app
gcloud compute firewall-rules create dressing-allow-pg-from-app --network="$NETWORK" \
    --direction=INGRESS --action=ALLOW --rules=tcp:5432 --source-tags=dressing-app --target-tags=dressing-db
gcloud compute firewall-rules create dressing-allow-ssh-jump --network="$NETWORK" \
    --direction=INGRESS --action=ALLOW --rules=tcp:22 --source-tags=dressing-app --target-tags=dressing-db

echo "== Cloud NAT: the DB VM has no public IP but still needs apt updates"
gcloud compute routers create dressing-router --network="$NETWORK" --region="$REGION"
gcloud compute routers nats create dressing-nat --router=dressing-router --region="$REGION" \
    --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges

echo "== One cloud service account per VM (least privilege; never the default compute SA)"
for vm in app db; do
    gcloud iam service-accounts create "sa-dressing-$vm" --display-name="Dressing $vm VM"
    for role in roles/logging.logWriter roles/monitoring.metricWriter; do
        gcloud projects add-iam-policy-binding "$PROJECT" --condition=None \
            --member="serviceAccount:sa-dressing-$vm@$PROJECT.iam.gserviceaccount.com" --role="$role"
    done
done

echo "== VMs (Debian 13). e2-micro + pd-standard: one of them can fall under the free tier."
gcloud compute instances create dressing-db --zone="$ZONE" --machine-type=e2-micro \
    --subnet="$SUBNET" --no-address --private-network-ip=10.10.0.20 \
    --image-family=debian-13 --image-project=debian-cloud \
    --boot-disk-size=20GB --boot-disk-type=pd-standard \
    --service-account="sa-dressing-db@$PROJECT.iam.gserviceaccount.com" --scopes=cloud-platform \
    --tags=dressing-db --shielded-secure-boot --deletion-protection

gcloud compute instances create dressing-app --zone="$ZONE" --machine-type=e2-micro \
    --subnet="$SUBNET" --private-network-ip=10.10.0.10 \
    --image-family=debian-13 --image-project=debian-cloud \
    --boot-disk-size=20GB --boot-disk-type=pd-standard \
    --service-account="sa-dressing-app@$PROJECT.iam.gserviceaccount.com" --scopes=cloud-platform \
    --tags=dressing-app --shielded-secure-boot

echo "Done. app = 10.10.0.10 (public IP: see 'gcloud compute instances list'), db = 10.10.0.20 (private only)."
