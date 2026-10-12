#!/usr/bin/env bash
# Google Cloud (project-level) roles for the people on the project.
# This is the layer ABOVE Linux: who may create/stop VMs, read logs, open SSH tunnels.
# Linux users/groups inside the VMs are set up separately by linux/*.sh.
# Usage: ./02_project_iam.sh admin@example.com devops@example.com auditor@example.com
set -euo pipefail
PROJECT="$(gcloud config get-value project)"
ADMIN="${1:?admin email}"; DEVOPS="${2:?devops email}"; AUDITOR="${3:?auditor email}"

bind() { gcloud projects add-iam-policy-binding "$PROJECT" --condition=None --member="user:$1" --role="$2" >/dev/null; echo "  $1 -> $2"; }

# Administrator: manages VMs, network and IAM (not Owner: Owner also controls billing and can delete the project).
bind "$ADMIN" roles/compute.admin
bind "$ADMIN" roles/iam.serviceAccountAdmin
bind "$ADMIN" roles/resourcemanager.projectIamAdmin

# DevOps: can start/stop/reset instances and SSH through IAP, cannot change firewall or IAM.
bind "$DEVOPS" roles/compute.instanceAdmin.v1
bind "$DEVOPS" roles/iam.serviceAccountUser
bind "$DEVOPS" roles/iap.tunnelResourceAccessor

# Auditor: read-only view of everything plus logs and IAM policies.
bind "$AUDITOR" roles/viewer
bind "$AUDITOR" roles/logging.viewer
bind "$AUDITOR" roles/iam.securityReviewer
