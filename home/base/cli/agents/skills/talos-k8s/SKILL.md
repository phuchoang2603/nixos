---
name: talos-k8s
description: Access Felix's Talos Kubernetes clusters (dev and prod) with the local kubeconfigs. Use when the user asks about k8s, kubectl, helm, nodes, pods, Argo CD, Cilium, Karpenter, AWS burst workers, or the talos-proxmox clusters.
---

# Talos Kubernetes access

Two independent Talos Kubernetes environments, `dev` and `prod`, from `talos-proxmox`. Each has its own local Argo CD and manages only itself; there is no separate `argocd` management cluster. Dev is ephemeral: it exists only after **Manual Provision** creates it, and its Doppler configs are removed on destroy. Do **not** use the default kubeconfig. Always pass `--kubeconfig` (or set `KUBECONFIG`) for the named environment.

Local access file locations (refresh after each cluster rebuild; keep them out of git):

| Env | File | Context | API VIP | Cluster name |
| --- | --- | --- | --- | --- |
| dev | `$HOME/.kube/talos-dev.yaml` | `admin@dev-talos` | `https://10.69.11.10:6443` | `dev-talos` |
| prod | `$HOME/.kube/talos-prod.yaml` | `admin@prod-talos` | `https://10.69.12.10:6443` | `prod-talos` |

If the user names an environment, use that file. If they do not, ask—or default to **dev**. Never point kubectl at prod unless they asked for prod.

## Fetching kubeconfigs via Doppler

Kubeconfigs and Talos configurations are stored as secrets in the Doppler project `talos-proxmox` under configs `dev` and `prod`.

Run from `~/repos/talos-proxmox` in `devenv shell`; it supplies Doppler, kubectl, talosctl, Helm, OpenTofu, and AWS CLI. Fetch the selected environment's configs successfully before continuing. Use `umask 077` before writing credentials so new files are private from creation.

```bash
# Login once if needed
doppler login

# Fetch kubeconfig for a specific cluster:
umask 077
mkdir -p "$HOME/.kube"
doppler secrets get KUBECONFIG --plain --project talos-proxmox --config dev > "$HOME/.kube/talos-dev.yaml"
chmod 600 "$HOME/.kube/talos-dev.yaml"

# Or refresh both environment kubeconfigs at once:
mkdir -p "$HOME/.kube"
for env in dev prod; do
  doppler secrets get KUBECONFIG --plain --project talos-proxmox --config "$env" > "$HOME/.kube/talos-$env.yaml"
  chmod 600 "$HOME/.kube/talos-$env.yaml"
done

# Talosctl configs (for node-level maintenance):
mkdir -p "$HOME/.talos"
for env in dev prod; do
  doppler secrets get TALOSCONFIG --plain --project talos-proxmox --config "$env" > "$HOME/.talos/config-$env.yaml"
  chmod 600 "$HOME/.talos/config-$env.yaml"
done
```

The Doppler `KUBECONFIG` secret contains YAML, not a filename. `doppler run -- kubectl` alone does not turn it into a usable config file; download it as above and select the file explicitly.

## Cluster usage

```bash
export KUBECONFIG="$HOME/.kube/talos-dev.yaml"
kubectl get nodes
kubectl get pods -A
```

Same pattern with an explicit flag:

```bash
kubectl --kubeconfig "$HOME/.kube/talos-prod.yaml" get ns
helm --kubeconfig "$HOME/.kube/talos-dev.yaml" list -A
```

Shell aliases on this machine: `k` = kubectl, `h` = helm, `kx`/`kn` = kubie.

## Inventory (from talos-proxmox)

Control-plane **node IPs** (Talos API). Kubernetes VIP is **only** for kube-apiserver. `talosctl` must use node IPs, not the VIP.

### dev

- VIP `10.69.11.10`, L2 pool `10.69.11.128-10.69.11.254`
- Fixed Proxmox control plane: `dev-server1` `10.69.11.11`; it also runs workloads, with no GPU passthrough in the current inventory
- Default StorageClass: `local-path`; no Longhorn or telemetry components

### prod

- VIP `10.69.12.10`, L2 pool `10.69.12.128-10.69.12.254`
- Control plane: `prod-server1` `10.69.12.11`, `prod-server2` `10.69.12.12`, `prod-server3` `10.69.12.13`
- These three Proxmox nodes also run workloads. There are no separate fixed Longhorn or GPU worker nodes. `prod-server1` has GPU passthrough and SSD-backed storage for write-heavy volumes.
- Default StorageClass: `local-path`; PVCs are node-bound, not replicated by Longhorn
- Grafana: `https://grafana.phuchoang.sbs`, LAN fallback `http://10.69.12.128`; that address is Grafana, not Longhorn

Treat `terraform/cluster/env/<env>/k8s_nodes.json` and `network.json` as the source of truth for inventory and addresses. Talos access example:

```bash
talosctl --talosconfig "$HOME/.talos/config-dev.yaml" \
  --endpoints 10.69.11.11 --nodes 10.69.11.11 version
```

### AWS burst workers (both environments)

- Karpenter launches temporary Talos EC2 workers from pending stateless workloads; zero AWS nodes when idle is normal. There is no Auto Scaling Group or Cluster Autoscaler.
- Pool `aws-burst`; node label `burst.talos.dev/compute=aws`, taint `burst.talos.dev/stateless=true:NoSchedule`. Workloads need the toleration; require matching node affinity when they must run on AWS.
- Keep persistent workloads and GPU workloads on Proxmox. AWS workers have disposable boot disks, no EBS CSI, and admission policy rejects persistent workloads opting into burst capacity.
- KubeSpan connects nodes; KubePrism provides worker API access through `localhost:7445`. Tailscale is for CI management access, not worker networking.
- Inspect `kubectl get nodepool,ec2nodeclass`, `kubectl get nodeclaims -o wide`, and `kubectl -n kube-system logs deploy/karpenter --tail=200` using the selected kubeconfig.

## Application architecture (talos-proxmox)

Repository is typically at `~/repos/talos-proxmox` (or sibling `../talos-proxmox`).

- **Provisioning (`terraform/cluster/` and `terraform/platform/`)**: The cluster root owns Proxmox/Talos, AWS infrastructure and worker credentials/configuration. The platform root owns Gateway API CRDs, Cilium, ESO bootstrap authentication, Karpenter and its NodePool/EC2NodeClass, and Argo CD independently in each environment. Cilium, Karpenter, and Argo CD remain OpenTofu-owned after bootstrap.
- **Argo CD (`apps/argocd/`)**: Each environment's local Argo CD reconciles its root platform Application and child Applications from `apps/argocd/platform/`.
- **Components (`apps/components/`)**: Argo CD owns ESO/store, Cilium address pools/L2 policies, local-path storage, metrics-server, Talos CCM, Istio ambient, operators, GPU components, and Cloudflare operator/tunnel. Observability (ClickHouse, Grafana, OTLP gateway/agents) and the shared Argo Workflows controller are prod-only. Check `apps/argocd/platform/values.yaml` for current component membership.
- Argo CD UI access is a bootstrap-owned LAN LoadBalancer Service, independent of Istio and Cloudflare: `http://10.69.11.254` (dev) and `http://10.69.12.254` (prod). The root Application is `platform`, in namespace `argo-cd`. Child Applications converge asynchronously; root health alone does not prove workload readiness.
- Cloudflare public hostnames are Git-owned `TunnelBinding` resources. Do not configure ingress rules for these tunnels in the Cloudflare dashboard; dashboard updates replace the operator's rules.

For setup, current addresses, and troubleshooting, consult `~/repos/talos-proxmox/docs/operations/cluster-access.md` and `docs/architecture/gitops.md`. For scaling or join issues, read `docs/operations/aws-burst-workers.md` and `docs/architecture/hybrid-aws-workers.md`. For prod ML workloads and shared controllers, read `docs/operations/kubeflow.md`.

## Safety

- Read-first: `get`, `describe`, `logs`, `helm list`. Confirm before `apply`, `delete`, `drain`, or Helm upgrades.
- Treat kubeconfigs as secrets. Do not paste certificate data into chat.
- Prefer namespaced queries. For Argo CD applications, use the selected environment's kubeconfig; Argo CD is local to each cluster.
