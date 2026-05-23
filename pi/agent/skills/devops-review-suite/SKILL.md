---
name: devops-review-suite
description: Default engineer-facing DevOps review suite. Use when asked to review a DevOps change, run review agents, or perform self-review before requesting review. Uses changed files only to choose domains, then reviews full relevant scope and runs summary deduplication. Does not run teamlead-overview unless explicitly requested.
compatibility: opencode
---

# DevOps Review Suite

Default engineer-facing entry point for DevOps work review.

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Contract

This suite is read-only. It may create review artifacts only:

- `reports/repository-scope-discovery.md`
- `reports/<selected-agent>.md`
- `reports/review-summary-deduplicator.md`
- `review-summary.md`

Do not run the optional `teamlead-overview` unless the user explicitly asks for teamlead/direct-report assessment.

## Core Principle

`git diff --name-only` is a trigger, not the review boundary. After selecting relevant domains, review the complete domain scope so regressions in unchanged files are caught.

## Workflow

This suite is a parent-orchestrated fanout/fanin workflow in the local `agent-team` extension.

Use the `subagent_dispatch` tool exactly. It delegates to the already-loaded active-team agents in the parent agent-team dashboard. `dispatch_agent` is an equivalent alias. Do not use pi-subagents' `subagent` tool for this workflow; that package discovers/spawns its own agents instead of reusing the loaded team state.

The coordinator must not personally perform all specialized reviews. It owns only routing, dispatch, progress tracking, and final synthesis.

1. Create `reports/` if missing.
2. Delegate `repository-scope-discovery` first with `subagent_dispatch`. The child must write `reports/repository-scope-discovery.md` and recommend which specialists should run.
3. Delegate `full-scope-regression-review` unless discovery proves there is no DevOps/infrastructure scope.
4. Based on discovery, delegate relevant specialized agents with one `subagent_dispatch` call per selected specialist:
   - `helm-chart-review` for `.helm/**`, `werf.yaml`, Helm/werf deploy commands.
   - `cicd-pipeline-review` for CI/CD files, includes, or deploy pipeline scripts.
   - `terraform-opentofu-review` for Terraform/OpenTofu/Terragrunt.
   - `kubernetes-gitops-review` for raw Kubernetes, Kustomize, Argo CD, Flux.
   - `container-supply-chain-review` for Dockerfiles, build scripts, image definitions.
   - `secrets-and-access-review` for secrets, IAM, RBAC, service accounts.
   - `observability-sre-review` for alerts, dashboards, monitoring, logging.
   - `change-readiness-review` for deploy/rollback/readiness and production-impacting changes.
   - `automation-script-review` for scripts, Makefiles, tooling.
   - `docs-runbook-review` for docs, runbooks, ADRs.
5. Pass each child agent the user's request, trigger files, discovery findings, the full-scope rule, the required output report path, and read-only/no-secret constraints.
6. Delegate `review-summary-deduplicator` last to read all reports, deduplicate findings, preserve highest severity, and write `review-summary.md`.
7. If `subagent_dispatch` and `dispatch_agent` are unavailable, stop and report that delegated review cannot run in this runtime. Do not silently replace specialist delegation with one large local review.

## Trigger Rules

Use changed files plus full inventory from discovery:

| Trigger | Skills |
|---|---|
| Any DevOps change | repository discovery, full-scope regression, summary deduplication |
| `.helm/**`, `werf.yaml`, Helm/werf commands | helm chart review, Kubernetes/GitOps if cluster integration matters |
| `.gitlab-ci*`, `.github/workflows/**`, `Jenkinsfile*`, CI includes | CI/CD review and any domain invoked by jobs |
| `*.tf`, `terragrunt.hcl`, Terraform modules | Terraform/OpenTofu, secrets/access, change readiness |
| `Dockerfile*`, `.dockerignore`, image build scripts | container supply chain, CI/CD |
| `k8s/**`, `manifests/**`, Kustomize, Argo CD, Flux | Kubernetes/GitOps, secrets/access |
| alerts, dashboards, monitoring config | observability/SRE |
| scripts, `bin/**`, `Makefile` | automation script review, plus callers' domain agents |
| docs, runbooks, ADRs | docs/runbook, change readiness |
| broad production impact | change readiness plus relevant technical agents |

## Output Requirements

The final `review-summary.md` must include:

- final recommendation for engineer self-review;
- list of agents run and skipped with reasons;
- full scope reviewed beyond changed files;
- deduplicated blockers;
- deduplicated warnings;
- missing context/skipped checks;
- next actions.

Do not include teamlead coaching notes unless `teamlead-overview` was explicitly requested.
