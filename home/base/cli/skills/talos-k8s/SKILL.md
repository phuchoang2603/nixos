---
name: talos-k8s
description: Access Felix's Talos Kubernetes clusters (dev, prod, argocd) with the local kubeconfigs. Use when the user asks about k8s, kubectl, helm, nodes, pods, Argo CD, Longhorn, Cilium, or the talos-proxmox clusters.
---

# Talos Kubernetes access

Three Talos clusters from `talos-proxmox`. Do **not** use the default kubeconfig. Always pass `--kubeconfig` (or `KUBECONFIG`) for the named env.

Kubeconfigs (already fetched, keep them out of git):

| Env | File | Context | API VIP | Cluster name |
| --- | --- | --- | --- | --- |
| dev | `$HOME/.kube/talos-dev.yaml` | `admin@dev-talos` | `https://10.69.11.10:6443` | `dev-talos` |
| prod | `$HOME/.kube/talos-prod.yaml` | `admin@prod-talos` | `https://10.69.12.10:6443` | `prod-talos` |
| argocd | `$HOME/.kube/talos-argocd.yaml` | `admin@argocd-talos` | `https://10.69.13.10:6443` | `argocd-talos` |

If the user names an env, use that file. If they do not, ask—or default to **dev**. Never point kubectl at prod unless they asked for prod.

## Fetching kubeconfigs via Doppler

Kubeconfigs and Talos configurations are stored as secrets in the Doppler project `talos-proxmox` under configs `dev`, `prod`, and `argocd`.

```bash
# Login once if needed
doppler login

# Fetch kubeconfig for a specific cluster:
mkdir -p "$HOME/.kube"
doppler secrets get KUBECONFIG --plain --project talos-proxmox --config dev > "$HOME/.kube/talos-dev.yaml"
chmod 600 "$HOME/.kube/talos-dev.yaml"

# Or refresh all three cluster kubeconfigs at once:
mkdir -p "$HOME/.kube"
for env in dev prod argocd; do
  doppler secrets get KUBECONFIG --plain --project talos-proxmox --config "$env" > "$HOME/.kube/talos-$env.yaml"
  chmod 600 "$HOME/.kube/talos-$env.yaml"
done

# Talosctl configs (for node-level maintenance):
mkdir -p "$HOME/.talos"
for env in dev prod argocd; do
  doppler secrets get TALOSCONFIG --plain --project talos-proxmox --config "$env" > "$HOME/.talos/config-$env.yaml"
  chmod 600 "$HOME/.talos/config-$env.yaml"
done
```

One-off command without saving:

```bash
doppler run --project talos-proxmox --config dev -- kubectl get nodes
```

## Cluster usage

```bash
export KUBECONFIG="$HOME/.kube/talos-dev.yaml"
kubectl get nodes
kubectl get pods -A
```

Same pattern with an explicit flag:

```bash
kubectl --kubeconfig "$HOME/.kube/talos-prod.yaml" get ns
helm --kubeconfig "$HOME/.kube/talos-argocd.yaml" list -A
```

Shell aliases on this machine: `k` = kubectl, `h` = helm, `kx`/`kn` = kubie.

## Inventory (from talos-proxmox)

Control-plane **node IPs** (Talos API). Kubernetes VIP is **only** for kube-apiserver. `talosctl` must use node IPs, not the VIP.

### dev

- VIP `10.69.11.10`, L2 pool `10.69.11.128-10.69.11.254`
- Control plane: `dev-server1` `10.69.11.11` (GPU passthrough)
- Default StorageClass: local-path (no Longhorn)
- GPU stack: NVIDIA GPU Operator + NVIDIA DRA Driver

### prod

- VIP `10.69.12.10`, L2 pool `10.69.12.128-10.69.12.254`
- Control plane: `prod-server1` `10.69.12.11`, `prod-server2` `10.69.12.12`, `prod-server3` `10.69.12.13`
- Longhorn storage nodes: `prod-longhorn1` `10.69.12.21`, `prod-longhorn2` `10.69.12.22`, `prod-longhorn3` `10.69.12.23`; Longhorn UI `http://10.69.12.128`
- Worker + GPU: `prod-worker1` `10.69.12.31`

### argocd

- VIP `10.69.13.10`, L2 pool `10.69.13.128-10.69.13.254`
- Control plane: `argocd-server1` `10.69.13.11`
- Argo CD UI `http://10.69.13.128`; manages **dev** and **prod** as remote clusters registered via Doppler kubeconfigs
- Default StorageClass: local-path

## Application architecture (talos-proxmox)

Repository is typically at `~/repos/talos-proxmox` (or sibling `../talos-proxmox`).

- **Bootstrap (`apps/bootstrap/`)**:
  - `bootstrap.sh`: Gateway API CRDs, Cilium CNI, Storage (`local-path` via containeroo Helm chart or `longhorn`), metrics-server, GPU operator + DRA driver.
  - `bootstrap-argocd.sh`: Deploys Argo CD on the `argocd` cluster, registers remote `dev` and `prod` clusters using Doppler credentials, and applies platform root apps.
- **Argo CD Platform App-of-Apps (`apps/argocd/roots/{dev,prod}.yaml`)**:
  - Roots live on the `argocd` management cluster and target each workload cluster (`dev`, `prod`).
  - `operators` namespace: External Secrets (`external-secrets`), CloudNativePG (`cnpg`), Strimzi Kafka (`strimzi`), MongoDB Operator (`mongodb`).
  - `monitoring` namespace: Observability stack (`victoria-metrics-k8s-stack`, Grafana).

## Safety

- Read-first: `get`, `describe`, `logs`, `helm list`. Confirm before `apply`, `delete`, `drain`, or Helm upgrades.
- Treat kubeconfigs as secrets. Do not paste certificate data into chat.
- Prefer namespaced queries. For Argo CD apps, use the **argocd** kubeconfig, not the workload cluster, unless inspecting app resources in-cluster.
