---
name: kubernetes-gitops-review
description: Reviews raw Kubernetes manifests, Kustomize, Argo CD, Flux, namespaces, RBAC, NetworkPolicy, PodSecurity, CRDs, and GitOps behavior. Use for Kubernetes/GitOps changes outside Helm internals or for rendered manifests. Reviews all affected bases/overlays/apps, not only changed files.
compatibility: opencode
---

# Kubernetes / GitOps Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Skill

Do not run `kubectl apply/delete/patch/replace`, `argocd app sync`, `flux reconcile`, or any cluster mutation. Local rendering/validation is allowed.

## Output

Write `reports/kubernetes-gitops-review.md`.

## Full-Scope Rule

If a shared base, overlay, namespace, RBAC object, CRD, GitOps application, or environment config changes, review all overlays/applications that consume it.

## Scope

- raw Kubernetes manifests (`k8s/**`, `kubernetes/**`, `manifests/**`, `deploy/**`)
- Kustomize bases/overlays (`kustomization.yaml`, `kustomization.yml`)
- Argo CD `Application`, `ApplicationSet`, projects
- Flux `Kustomization`, `HelmRelease`, `GitRepository`, `OCIRepository`
- namespace, RBAC, NetworkPolicy, ResourceQuota, LimitRange
- rendered manifests provided by Helm/werf review

## Discovery

```bash
mkdir -p reports

find . -path './.git' -prune -o \( -name 'kustomization.yaml' -o -name 'kustomization.yml' -o -path './k8s/*' -o -path './kubernetes/*' -o -path './manifests/*' -o -path './deploy/*' -o -path './argocd/*' -o -path './flux/*' -o -path './clusters/*' -o -path './apps/*' \) -print 2>/dev/null | sort

grep -RInE "^kind: (Application|ApplicationSet|AppProject|Kustomization|HelmRelease|GitRepository|OCIRepository|ClusterRole|ClusterRoleBinding|Role|RoleBinding|ServiceAccount|NetworkPolicy|ResourceQuota|LimitRange|PodDisruptionBudget|HorizontalPodAutoscaler|Secret|ExternalSecret|Certificate|Issuer|ClusterIssuer|PrometheusRule|ServiceMonitor|PodMonitor)" . 2>/dev/null | grep -v './.git/' | head -500

grep -RInE "(namespace:|serviceAccountName:|hostNetwork:|hostPID:|hostIPC:|privileged:|runAsUser: 0|allowPrivilegeEscalation: true|hostPath:|0\.0\.0\.0/0|syncPolicy:|prune:|selfHeal:|ignoreDifferences:)" . --include='*.yaml' --include='*.yml' 2>/dev/null | grep -v './.git/' | head -500
```

## Rendering / Validation

Run only local read-only commands when available:

```bash
# Kustomize
find . -name 'kustomization.yaml' -o -name 'kustomization.yml' 2>/dev/null | while read -r k; do
  d=$(dirname "$k")
  echo "=== kustomize build $d ==="
  kustomize build "$d" >/tmp/pi-kustomize-review.yaml
 done

# kubectl client dry-run validation for existing YAML if safe and no cluster mutation
kubectl apply --dry-run=client -f <file-or-rendered-dir>
```

`kubectl apply --dry-run=client` is allowed only as local validation; do not use server-side dry-run unless the user explicitly approves cluster reads.

Use documentation lookup for operator-specific resources when a CRD/operator is detected (Argo CD, Flux, cert-manager, external-secrets, Prometheus Operator, Istio, CNPG, etc.).

## Review Checks

### BLOCK / HIGH

- Render/build fails for Kustomize or manifests are invalid YAML.
- Cluster-scoped RBAC grants broad permissions without justification.
- Workload runs privileged, root, hostNetwork/hostPID/hostIPC, or hostPath without explicit accepted reason.
- Plain Kubernetes Secret contains sensitive base64 data in repo without encryption policy.
- GitOps app can prune/self-heal production resources without safeguards or clear ownership.
- Application/overlay points production at mutable branch, unpinned chart, or wrong namespace/cluster.
- Namespace/RBAC mismatch would deploy resources into wrong namespace or bind wrong subjects.
- CRD version incompatible with operator version or deprecated API version used.

### MED / LOW

- Missing NetworkPolicy for sensitive namespaces/workloads.
- Missing PDB/HPA/resource quota/limit range where expected.
- Inconsistent labels/selectors across Service/Deployment/Monitor/Policy.
- Missing owner/team/environment labels.
- GitOps ignore rules too broad or undocumented.
- Overlays drift between dev/stage/prod without explanation.

## Helm Pairing

If Helm charts are involved, do not duplicate Helm lint/template internals. Use `helm-chart-review` output for rendered chart safety, then review cluster/GitOps integration:

- Argo/Flux app source and values selection;
- namespace and RBAC integration;
- sync/prune behavior;
- policy resources outside the chart.

## Report Requirements

`reports/kubernetes-gitops-review.md` must include:

- manifests/apps/bases/overlays reviewed;
- full consumer mapping beyond changed files;
- render/validation commands and results;
- cluster-scope, RBAC, security, GitOps, operator compatibility findings;
- skipped checks and why.
