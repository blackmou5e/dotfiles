---
name: repository-scope-discovery
description: Inventories full DevOps-related repository scope before review. Use at the start of DevOps reviews to map changed files to affected domains and discover full scopes such as Helm, CI/CD, Terraform, Kubernetes/GitOps, Docker, scripts, secrets, observability, and docs.
compatibility: opencode
---

# Repository Scope Discovery

Read shared rules first: `../_shared/devops-review-common.md`.

## Purpose

Build a repository inventory and map changed files to review domains. Changed files are trigger signals only; this skill discovers the complete relevant scope that downstream agents must review.

## Output

Write `reports/repository-scope-discovery.md`.

If useful, also write `reports/scope-inventory.json` with domain lists and triggering files.

## Discovery Workflow

1. Create `reports/` if missing.
2. Capture repository state:

```bash
git rev-parse --show-toplevel 2>/dev/null || pwd
git status --short 2>/dev/null || true
git branch --show-current 2>/dev/null || true
git remote -v 2>/dev/null || true
```

3. Capture changed files. Try multiple safe bases because local repos differ:

```bash
{
  git diff --name-only origin/main...HEAD 2>/dev/null
  git diff --name-only origin/master...HEAD 2>/dev/null
  git diff --name-only main...HEAD 2>/dev/null
  git diff --name-only master...HEAD 2>/dev/null
  git diff --name-only HEAD~1...HEAD 2>/dev/null
  git diff --name-only --cached 2>/dev/null
  git ls-files --others --exclude-standard 2>/dev/null
} | sort -u
```

4. Inventory full domain scope. Prefer `fffind`; safe fallback commands:

```bash
# Helm / werf
find . -path './.git' -prune -o \( -name 'Chart.yaml' -o -path './.helm/*' -o -name 'werf.yaml' -o -name 'werf-giterminism.yaml' \) -print 2>/dev/null | sort

# CI/CD
find . -path './.git' -prune -o \( -name '.gitlab-ci.yml' -o -name '.gitlab-ci*.yml' -o -path './.gitlab-ci/*' -o -path './.gitlab/*' -o -path './.github/workflows/*' -o -path './.github/actions/*/action.y*ml' -o -name 'Jenkinsfile' -o -name 'Jenkinsfile.*' -o -path './jenkins/*' -o -path './.jenkins/*' \) -type f -print 2>/dev/null | sort

# Terraform / OpenTofu / Terragrunt
find . -path './.git' -prune -o \( -name '*.tf' -o -name '*.tfvars' -o -name '.terraform.lock.hcl' -o -name 'terragrunt.hcl' -o -name 'terragrunt.hcl.json' \) -type f -print 2>/dev/null | sort

# Kubernetes / GitOps
find . -path './.git' -prune -o \( -name 'kustomization.yaml' -o -name 'kustomization.yml' -o -path './k8s/*' -o -path './kubernetes/*' -o -path './manifests/*' -o -path './argocd/*' -o -path './flux/*' -o -path './clusters/*' -o -path './apps/*' \) -print 2>/dev/null | sort

# Containers / image build
find . -path './.git' -prune -o \( -name 'Dockerfile' -o -name 'Dockerfile.*' -o -name '.dockerignore' -o -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' -o -name 'werf.yaml' \) -type f -print 2>/dev/null | sort

# Scripts / automation
find . -path './.git' -prune -o \( -path './scripts/*' -o -path './bin/*' -o -path './tools/*' -o -path './hack/*' -o -name '*.sh' -o -name '*.bash' -o -name 'Makefile' -o -name '*.mk' \) -type f -print 2>/dev/null | sort

# Observability / docs
find . -path './.git' -prune -o \( -iname '*prometheus*' -o -iname '*alert*' -o -iname '*grafana*' -o -iname '*dashboard*' -o -iname '*runbook*' -o -iname 'README*' -o -path './docs/*' -o -path './adr/*' \) -type f -print 2>/dev/null | sort
```

5. Discover indirect links:

```bash
# CI includes and called scripts
grep -RInE "(^\s*include:|uses:|run:|script:|make |bash |sh |python |terraform |tofu |terragrunt |helm |werf |kubectl |kustomize |argocd |flux)" \
  .gitlab-ci.yml .gitlab-ci .github/workflows Jenkinsfile* jenkins .jenkins 2>/dev/null | head -300

# Kubernetes resource kinds and operators
grep -RInE "^kind: (Application|ApplicationSet|Kustomization|HelmRelease|ClusterRole|RoleBinding|Secret|ExternalSecret|PrometheusRule|ServiceMonitor|PodMonitor)" \
  . . 2>/dev/null | grep -v './.git/' | head -300
```

## Domain Classification

Classify each changed file and each discovered domain:

- Helm/werf chart review needed?
- CI/CD review needed?
- Terraform/OpenTofu review needed?
- Kubernetes/GitOps review needed?
- Container supply-chain review needed?
- Secrets/access review needed?
- Observability/SRE review needed?
- Change readiness review needed?
- Automation script review needed?
- Docs/runbook review needed?

For each selected domain, record both:

- **Triggering changed files**
- **Full domain scope to review**

## Report Requirements

`reports/repository-scope-discovery.md` must include:

- repository and branch context;
- changed files detected;
- full inventory by domain;
- selected downstream agents and why;
- skipped agents and why;
- missing tools/context that may affect validation;
- full-scope regression risks, e.g. shared modules, shared values, common CI templates.
