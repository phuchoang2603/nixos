---
name: talos-k8s
description: >-
  Operate Felix's Talos Kubernetes environments in talos-proxmox: Proxmox dev and
  GCP prod. Use for cluster access, node and workload troubleshooting, Argo CD
  reconciliation, Cluster Autoscaler scaling, storage, quotas, or infrastructure changes in these environments.
---

# Talos Kubernetes operations

Work from `~/repos/talos-proxmox` (or the sibling checkout) in `devenv shell`. Read its local instructions and current configuration before acting. Use the environment named in the request or established in the session. If neither identifies a target, use dev for initial read-only investigation and clarify the target before mutation. Existing authorization carries forward; do not require another confirmation for each command in an authorized rollout.

Always select the environment's kubeconfig explicitly. Each cluster has its own Argo CD; there is no separate management cluster and neither cluster manages the other.

Production moved from AWS to GCP on 2026-11-02 because the AWS account could no longer be used. The AWS module (`terraform/aws`) remains as an alternative selected by `cloud_provider`, but nothing runs there and its account is closed. Karpenter is gone from both environments.

## Environments and sources of truth

| | Dev | Prod |
| --- | --- | --- |
| Infrastructure | Proxmox `pve`, `pve2`, `pve3` | GCP project `talos-proxmox`, `us-central1-a`, paid account on the free-trial credit |
| Control plane + workloads | `dev-server1`, `10.69.12.11`, 8 CPU / 32 GiB, GPU passthrough | One `e2-standard-4` (4 vCPU / 16 GiB), private IP `10.81.0.10` |
| Baseline workers | `dev-server2` `.12`, 8 CPU / 16 GiB; `dev-server3` `.13`, 4 CPU / 16 GiB | Three On-Demand `e2-standard-4` in MIG `prod-talos-cpu`, fixed at 3 |
| Elastic capacity | Fixed local VMs | Spot `e2-standard-4` in MIG `prod-talos-spot`, 0 to 12, Cluster Autoscaler |
| Kubernetes API | Control-plane node directly, port 6443 | Reserved static public address, port 6443 |
| Default PVC storage | Node-local `local-path` | `cloud-block` StorageClass: GCE PD CSI, `pd-balanced`, single zone, `reclaimPolicy: Retain`, `WaitForFirstConsumer` |
| Object storage | Existing external MinIO, bucket `platform-dev` | GCS through the S3 XML API with HMAC keys: `talos-proxmox-prod-platform` (shared by training and the gateway), `-artifacts`, `-substrate` |
| Local kubeconfig | `$HOME/.kube/talos-dev.yaml` | `$HOME/.kube/talos-prod.yaml` |
| Local Talos config | `$HOME/.talos/config-dev.yaml` | `$HOME/.talos/config-prod.yaml` |

The prod baseline is 16 vCPU / 64 GiB across four nodes before system reservations; the Spot group adds up to 48 vCPU. Both environments have one control plane; they are not HA. Local-path volumes are node-bound; a PD can reattach to a replacement node in the same zone but does not make the cluster or a single-instance database HA. MinIO and GCS hold objects, not ordinary PVCs. GCS is an S3 subset: use endpoint `https://storage.googleapis.com`, signing region `auto`, path-style addressing, and no object tagging.

Treat this table as orientation, not an inventory cache. Check:

- `terraform/cluster/env/dev/k8s_nodes.json` and `main.tfvars` for Proxmox nodes, addresses and allocations.
- `terraform/cluster/env/prod/main.tfvars` and `terraform/gcp/` (`main.tf`, `workers.tf`, `iam.tf`, `outputs.tf`) for machine type, group bounds, boot disks and IAM. Discover the API address from generated access files or `gcloud`; do not hard-code it.
- `terraform/gcp/foundation/` for buckets, HMAC identities, CI federation and the Talos image.
- `apps/components/cluster-autoscaler/`, `apps/components/gce-pd-csi/` and the component `environments/prod/values.yaml` overlays for autoscaler groups, storage and prod-only sizes.
- `apps/argocd/platform/values.yaml` and component overlays for actual deployment membership, namespaces and environment differences.

## Access

Doppler project `talos-proxmox`, configs `dev` and `prod`, holds YAML-valued `KUBECONFIG` and `TALOSCONFIG` secrets, written by the cluster root only after a successful apply. Refresh access files after rebuilds or credential rotation. A destroyed or half-applied environment may have no access secrets until Manual Provision completes.

Fetch only the selected environment. Write downloads to private temporary files and move them into place only after successful retrieval, so a failed fetch cannot empty a working config:

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

The Doppler secret is YAML, not a path: `doppler run -- kubectl` does not select a usable kubeconfig. Do not print credentials, raw Secret objects, complete Helm values or unfiltered OpenTofu plans/state; Helm metadata can expose machine configuration even when inputs were marked sensitive. When comparing secret values, compare hashes and list names only. Keep access files, saved plans, state backups and etcd snapshots private and out of Git; this repository is public.

Dev management needs LAN/tailnet routing; CI joins Tailscale. Prod management ports are restricted to declared operator/CI CIDRs (`CLOUD_MANAGEMENT_CIDRS` in Doppler, plus the runner's /32). For Talos, use the configured management endpoint and explicitly target the node's private IP. Select exactly one control-plane node for an etcd snapshot. Neither cluster uses a Kubernetes API VIP, Cilium LAN pools or L2 announcements.

## Ownership and deployment

- **Foundation**, applied by an operator from a local machine, owns the cloud CI identity (Workload Identity Federation), object buckets and HMAC identities, the Talos image, Doppler project/environments/service tokens, GitHub Environments and HCP workspaces. It also writes an allowlist of operator-entered Doppler keys from a private `operator_secrets` tfvars file outside Git (`operator-secrets.tf`). It does not manage application secrets.
- **Cluster roots**, `terraform/cluster/dev` and `prod`, own Proxmox or GCP infrastructure, Talos identity/bootstrap and generated access/worker credentials written to Doppler. On GCP they own the control-plane VM, network, instance templates, MIGs, service accounts and IAM.
- **Platform root**, `terraform/platform`, owns bootstrap networking (Gateway API CRDs, Cilium, Talos CCM), ESO authentication, Argo CD and its root Application, and the autoscaler's cloud credentials and group list. Read the actual resource definitions when an ownership boundary is unclear.
- **Argo CD** in each cluster reconciles its pinned platform revision (the commit that ran the apply) and component Applications. ESO reads environment-scoped Doppler secrets into Kubernetes. Change the owning Git/Tofu/Doppler configuration rather than leaving a live patch that its controller will revert.
- **Application secrets** (database passwords, OIDC and signing keys, Grafana admin) are entered in Doppler by hand. Secrets used only by the gateway repository live in its own Doppler project and are read through its `gateway-doppler` store; the platform `doppler` store serves only platform components and the few values shared with it.

HCP stores and locks state; OpenTofu executes locally or in CI. Select `TF_WORKSPACE=talos-cluster-<env>` or `talos-platform-<env>` inside the devenv command, since entering the shell unsets it. Foundation uses `talos-proxmox`. A local foundation run needs `DOPPLER_TOKEN=$(doppler configure get token --plain)` and `GITHUB_TOKEN=$(gh auth token)`, plus `-var-file` pointing at the private inputs. Export the Doppler `HCP_TERRAFORM_TOKEN` as `TF_TOKEN_app_terraform_io` without displaying it. Roots exchange credentials through Doppler, not remote-state reads.

Pushes to main deploy dev. Trusted repository PRs, including Renovate branches, also deploy dev and plan prod, so dev applies are frequent and share one concurrency group; a queued run can cancel a pending one, so re-run a cancelled job rather than treating it as a failure. Production is applied by running **Manual Provision** (`prod`, `apply`) on main after dev succeeds on the same commit: `gh workflow run "Manual Provision" --ref main -f environment=prod -f action=apply`. A successful OpenTofu apply does not prove child Applications or workloads have converged.

Branch protection requires some check names that no longer exist, so PRs may stay `BLOCKED` with every real check green. The owner has authorized pushing to main directly or admin-merging for this repository; confirm that authorization is still current in the session before relying on it.

Argo CD uses ClusterIP in both environments; access it by management port-forward or its Git-owned Cloudflare tunnel binding. Dev hostnames use `<service>-dev.phuchoang.sbs`; prod uses `<service>.phuchoang.sbs`. Do not replace operator-managed tunnel routes in the Cloudflare dashboard.

The gateway repository deploys through `deploy/dev` (published from trusted PRs) and `deploy/prod` (published from its main); pushing to its main does not by itself change dev.

## Autoscaling, quotas and maintenance

Cluster Autoscaler runs on the control plane with explicit `--nodes=min:max:<instanceGroups URL>` for each MIG. The URL must be an `instanceGroups` URL, not `instanceGroupManagers`; the GCE provider exits at startup otherwise. Node labels `talos.dev/nodepool` and `talos.dev/capacity-type` (`on-demand` or `spot`) come from the instance template's `kube-env` metadata, which is how it builds a template for a group at size 0. Terraform ignores `target_size` drift; the autoscaler owns it. The update policy is `OPPORTUNISTIC`, so template changes never replace running workers: delete or `recreate-instances` the workers deliberately after changing a template.

Spot instances in a MIG must use termination action `STOP`; `DELETE` is rejected. Spot boot disks are `pd-standard` so they do not consume the SSD quota; On-Demand nodes and all PVCs use `pd-balanced`. The autoscaler scales from pending pods and removes unneeded nodes after the configured delays (about ten minutes); it does not react to low or high node usage, and application replica scaling is separate. Compare requests, measured usage and allocatable capacity before shrinking nodes. Account for Talos/system reservations (500m CPU and 1536 MiB per node), DaemonSets, placement constraints and same-zone PD attachment. Preserve cloud-provider/Cilium startup taints until their controllers initialize the node. KubePrism is Talos's local API proxy, not an external VIP.

Quotas are the usual blocker on this project:

- `CPUS_ALL_REGIONS` 64, `IN_USE_ADDRESSES` in `us-central1` 16, `INSTANCES` 24 (raised or default; check live).
- `SSD_TOTAL_GB` is 300 per region and counts every `pd-balanced` disk (boot disks and PVCs). Check usage with `gcloud compute regions describe us-central1`.
- `PREEMPTIBLE_CPUS` is 0; Spot VMs count against the normal CPU quota.
- A failed VM creation shows up as `QUOTA_EXCEEDED` in `gcloud compute instance-groups managed list-errors <mig>` and as a scale-up backoff in the autoscaler log.
- Request increases with `gcloud beta quotas preferences create --service=compute.googleapis.com --quota-id=<ID> --preferred-value=<n> --preference-id=<name> --email=<account> [--dimensions=region=us-central1] --justification=...`. An email is required, requests are rate limited per day, and `describe` shows `grantedValue` once approved.

`cloud-block` keeps the disk and PV after a PVC is deleted (`Retain`). A PVC cannot shrink, so right-sizing means recreating the claim (for a CNPG cluster, deleting the `Cluster`), and the old `Released` PV and its GCE disk keep counting against `SSD_TOTAL_GB` until you delete both. Confirm a disk has no users before deleting it. Prod volume sizes are per-environment values in the component `environments/prod/values.yaml`; dev keeps its larger sizes because dev PVCs cannot be shrunk by a template change.

For a control-plane resize, inspect the OpenTofu plan for stop/start versus replacement, preserve the boot disk/etcd identity and stable address, and take an etcd snapshot before disruptive maintenance. Single-control-plane API downtime is expected. Recover API, kubelet and Cilium readiness before reducing worker capacity. Respect PDBs during drain; inspect blocked pods and their owners before choosing recovery. Do not routinely bypass budgets or remove finalizers; when a finalizer's controller is permanently gone (for example the Karpenter `EC2NodeClass` finalizer on dev after the AWS account closed), remove it deliberately and say so.

## Diagnose and verify

Start with selected-environment `get`, `describe`, events and bounded logs. Distinguish unscheduled Pending pods from scheduled pods waiting for images, CNI, admission webhooks or volumes.

```bash
kubectl get --raw=/readyz
kubectl get nodes -L talos.dev/nodepool,talos.dev/capacity-type
kubectl top nodes
kubectl get applications -n argo-cd
kubectl get pods -A
kubectl -n kube-system logs deploy/cluster-autoscaler --tail=100
gcloud compute instance-groups managed list --project talos-proxmox
gcloud compute instance-groups managed list-errors prod-talos-spot --zone us-central1-a --project talos-proxmox
gcloud compute instances get-serial-port-output <instance> --zone us-central1-a --project talos-proxmox
```

For a worker that runs but never registers, read its serial console: Talos rejects configs that put control-plane-only documents (for example `KubeTalosAPIAccessConfig`) on workers. For scheduling, inspect pod requests and selectors, autoscaler backoff messages and group bounds; for storage, inspect PVC/PV topology and attach events (`SERVICE_ACCOUNT_ACCESS_DENIED` means the PD CSI account lacks `iam.serviceAccountUser` on the node service account); for webhooks, inspect Service endpoints, certificates, controller readiness and network policies before disabling admission.

Argo CD sync operations record the revision they started on. If an Application stays `OutOfSync` with an operation `Running` on an old revision (typically waiting for a resource that never became healthy), it keeps re-applying stale manifests; compare `status.operationState.syncResult.revision` with `spec.source.targetRevision`, then terminate it by patching `status.operationState.phase` to `Terminating` and let it restart. A resource that Argo created from stale manifests must be deleted for the new sizes or settings to take effect.

HCP lock failures: `Error releasing the state lock ... state version upload is still pending` leaves the workspace locked after a run finishes. Confirm no run is in progress or queued (`gh run list --status in_progress`), then unlock with `POST /api/v2/workspaces/<id>/actions/unlock` using the token in `~/.terraform.d/credentials.tfrc.json`, or `tofu force-unlock -force <workspace-path>` (the lock ID is the `organization/workspace` path, not the UUID in the message). Never unlock while a run holds the lock.

Use `data` for shared data services and downstream Spark/Flink jobs, `ml` for Kubeflow/KServe/training, and `operators` for shared operators, storage provisioners and Argo Workflows. Retain `istio-system`, `auth`, `argo-cd` and `observability`; Knative is no longer deployed and KServe runs in Standard mode. Avoid reintroducing application-specific namespaces into platform ownership. Check current manifests when old namespaces are still present during a migration.

Read `docs/operations/cluster-access.md` for access/convergence, `docs/operations/gcp-workers.md` and `docs/architecture/gcp-workers.md` for scaling and storage, `docs/architecture/terraform-ci.md` for state/CI, `docs/architecture/gitops.md` for reconciliation, and `docs/reference/secrets.md` for credential ownership. Report the verified nodes, group bounds, quota headroom, workload health and any unresolved failures separately; do not equate a Ready node with a healthy full platform.
