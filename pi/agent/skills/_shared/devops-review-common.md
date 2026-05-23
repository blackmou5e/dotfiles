# DevOps Review Common Instructions

These instructions are shared by the DevOps review skills in this repository.

## Operating Mode

- Be read-only. Do not edit, fix, delete, deploy, apply, or mutate infrastructure.
- Allowed writes are review artifacts only, normally under `reports/`, plus the final `review-summary.md` when running the summary agent.
- Use changed files only as trigger signals. Once a domain is selected, review the complete relevant domain scope.
- Prefer evidence over opinion. Every finding should include file path, line number when available, command output, or a clear note that evidence is missing.
- Never print secret values. If a secret is found, report only file path, line, key/name, and secret type.
- Mark checks as `SKIPPED` or `INCOMPLETE` when tools, credentials, cluster access, provider access, or CI context are unavailable.

## Severity

- `BLOCK`: must be fixed before merge/deploy; likely breakage, data loss, credential exposure, unsafe production change, or failed validation.
- `HIGH`: serious risk that should normally be fixed before merge unless accepted explicitly.
- `MED`: important quality, reliability, security, or operability issue.
- `LOW`: improvement or maintainability issue.
- `INFO`: context, skipped check, or non-blocking observation.

## Default Report Layout

Specialized agents should write `reports/<agent-name>.md` with this structure:

```md
## Review Result: <agent-name>

### Decision
- Recommendation: APPROVE / APPROVE WITH WARNINGS / REQUEST CHANGES / NEEDS CONTEXT
- Highest severity: BLOCK/HIGH/MED/LOW/INFO

### Scope Reviewed
- Triggering changed files:
- Full domain scope reviewed:
- Commands run:
- Assumptions/missing context:

### Blocking Findings
| Severity | Issue | Evidence | Why it matters | Suggested action |
|---|---|---|---|---|

### Warnings / Improvements
| Severity | Issue | Evidence | Suggested action |
|---|---|---|---|

### Questions / Missing Context
- ...

### Improvement Notes
- ...
```

The summary agent writes `review-summary.md` and may also write `reports/review-summary-deduplicator.md`.

The optional teamlead agent writes `reports/teamlead-overview.md` only when explicitly requested.

## Discovery Commands

Use fast file search first, then read top matches:

```bash
git status --short 2>/dev/null || true
git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only HEAD~1...HEAD 2>/dev/null || true
git diff --name-only --cached 2>/dev/null || true
find . -maxdepth 4 -type f \( -name '.gitlab-ci*.yml' -o -path './.github/workflows/*' -o -name 'Jenkinsfile*' -o -name 'werf.yaml' -o -name 'Chart.yaml' -o -name '*.tf' -o -name 'terragrunt.hcl' -o -name 'Dockerfile*' -o -name 'kustomization.y*ml' \) 2>/dev/null | sort
```

Prefer `fffind` and `ffgrep` when available for repository-scale path/content search.

## Safe Command Rules

Allowed examples:

```bash
# discovery
find . -type f ...
grep -RIn ...

# validation without mutation
terraform fmt -check -recursive
terraform validate
terraform plan -refresh=false -lock=false -out=/tmp/pi-review.tfplan
helm lint .helm/<chart>
helm template <release> .helm/<chart>
werf render --dev --ignore-secret-key
shellcheck scripts/*.sh
```

Do not run commands that mutate infrastructure or remote state, including:

```bash
kubectl apply|delete|patch|replace|scale|rollout restart
helm upgrade|install|uninstall
werf converge|dismiss|cleanup
terraform apply|destroy|import|state rm|state mv
aws/gcloud/az delete|create|update commands
```

If a validation command requires credentials or would mutate state, skip it and report why.
