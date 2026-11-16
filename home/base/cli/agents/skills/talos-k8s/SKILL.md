---
name: talos-k8s
description: >-
  Access Felix's Talos Kubernetes environments in talos-proxmox (Proxmox dev, GCP
  prod): fetch kubeconfig and talosconfig from Doppler and handle secrets safely.
  Use before any kubectl, talosctl or Argo CD work in these clusters.
---

# Talos cluster access and secrets

Work from `~/repos/talos-proxmox` (or the sibling checkout) in `devenv shell`, and read its docs before acting: `docs/operations/cluster-access.md` for access and convergence, `docs/architecture/gitops.md` for Argo CD, `docs/architecture/terraform-ci.md` for CI and state, `docs/reference/secrets.md` for credential ownership. Treat the repo as the source of truth for topology, sizing, quotas and deployment flow rather than anything cached here.

Use the environment named in the request or session. If none is named, use dev for read-only investigation and ask before changing anything. Each environment has its own cluster and its own Argo CD; neither manages the other. Always select the kubeconfig explicitly.

| | Dev | Prod |
| --- | --- | --- |
| Where | Proxmox | GCP |
| Kubeconfig | `$HOME/.kube/talos-dev.yaml` | `$HOME/.kube/talos-prod.yaml` |
| Talos config | `$HOME/.talos/config-dev.yaml` | `$HOME/.talos/config-prod.yaml` |
| Management access | LAN or tailnet | Operator and CI CIDRs only (`CLOUD_MANAGEMENT_CIDRS` in Doppler) |

## Fetch access

Doppler project `talos-proxmox`, configs `dev` and `prod`, holds YAML-valued `KUBECONFIG` and `TALOSCONFIG`. The cluster root writes them only after a successful apply, so a destroyed or half-applied environment may have none. Refresh after a rebuild or credential rotation.

Fetch only the selected environment, into private temporary files that replace the old ones only on success, so a failed fetch cannot empty a working config:

```bash
set -e
export CLUSTER_ENV=dev
umask 077
mkdir -p "$HOME/.kube" "$HOME/.talos"
kube_tmp=$(mktemp "$HOME/.kube/.talos-${CLUSTER_ENV}.XXXXXX")
talos_tmp=$(mktemp "$HOME/.talos/.talos-${CLUSTER_ENV}.XXXXXX")
trap 'rm -f "$kube_tmp" "$talos_tmp"' EXIT
doppler secrets get KUBECONFIG --plain --project talos-proxmox --config "$CLUSTER_ENV" > "$kube_tmp"
doppler secrets get TALOSCONFIG --plain --project talos-proxmox --config "$CLUSTER_ENV" > "$talos_tmp"
mv "$kube_tmp" "$HOME/.kube/talos-${CLUSTER_ENV}.yaml"
mv "$talos_tmp" "$HOME/.talos/config-${CLUSTER_ENV}.yaml"
export KUBECONFIG="$HOME/.kube/talos-${CLUSTER_ENV}.yaml"
export TALOSCONFIG="$HOME/.talos/config-${CLUSTER_ENV}.yaml"
kubectl config current-context
kubectl get nodes -o wide
```

The Doppler value is YAML content, not a path, so `doppler run -- kubectl` does not select a usable kubeconfig. For Talos, use the configured endpoint and target a node's private IP explicitly. Neither cluster has a Kubernetes API VIP.

## Secrets

- Platform secrets live in Doppler project `talos-proxmox`, one config per environment. External Secrets Operator reads them into the cluster; the platform `doppler` store serves only platform components.
- Application secrets (database passwords, OIDC and signing keys, Grafana admin) are entered in Doppler by hand. Secrets used only by the gateway repository live in its own Doppler project and are read through its `gateway-doppler` store.
- OpenTofu roots exchange credentials through Doppler, not remote state. For HCP, export the Doppler `HCP_TERRAFORM_TOKEN` as `TF_TOKEN_app_terraform_io` without displaying it.

Read secrets into variables or private files; never echo them. Do not print credentials, raw Secret objects, full Helm values or unfiltered OpenTofu plans and state, because Helm metadata can expose machine configuration even when inputs were marked sensitive. To compare secret values, compare hashes and list names only. Keep access files, saved plans, state backups and etcd snapshots private and out of Git; the repository is public.

Change the owning Git, OpenTofu or Doppler configuration rather than patching a live object that its controller will revert.
