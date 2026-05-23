---
name: docs-runbook-review
description: Reviews DevOps documentation, README files, runbooks, ADRs, deployment/rollback instructions, ownership, monitoring notes, examples, and environment-specific operational guidance. Use for docs/runbook changes or when technical changes require documentation. Reviews all affected docs, not only changed files.
compatibility: opencode
---

# Docs / Runbook Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Skill

Do not edit documentation during review. Only report gaps and suggestions.

## Output

Write `reports/docs-runbook-review.md`.

## Full-Scope Rule

If behavior, deploy process, ownership, alerts, environments, or operational assumptions change, review all docs/runbooks that describe the affected system or process, not only changed markdown files.

## Scope

- `README*`
- `docs/**`
- `RUNBOOK*`, `runbooks/**`
- `ADR*`, `adr/**`
- inline operational comments in CI, scripts, manifests, Terraform
- examples and command snippets

## Discovery

```bash
mkdir -p reports

find . -path './.git' -prune -o \( -iname 'README*' -o -path './docs/*' -o -iname '*RUNBOOK*' -o -path './runbooks/*' -o -iname 'ADR*' -o -path './adr/*' -o -iname '*.md' \) -type f -print 2>/dev/null | sort

grep -RInE "(deploy|rollback|restore|backup|monitor|alert|dashboard|runbook|owner|on-call|escalat|environment|prod|stage|dev|namespace|cluster|terraform|helm|werf|kubectl|secret|token|password|example|TODO|FIXME|deprecated)" . --include='*.md' --include='*.rst' --include='*.txt' 2>/dev/null | grep -v './.git/' | head -500
```

## Review Checks

### BLOCK / HIGH

- Production-impacting change lacks essential deploy or rollback documentation when no other source provides it.
- Runbook for paging alert is missing, broken, or clearly stale.
- Docs instruct unsafe commands by default, e.g. production mutation, delete, destroy, or secret printing without guardrails.
- Docs contain real secrets, tokens, private keys, or kubeconfigs.
- Environment/cluster/namespace instructions point to wrong or ambiguous target.

### MED / LOW

- What changed and why is unclear.
- Acceptance criteria or verification steps are missing.
- Rollback instructions exist but do not include prerequisites or expected impact.
- Monitoring/dashboard links missing for operational change.
- Ownership/contact/escalation absent or stale.
- Examples are outdated relative to scripts/CI/manifests.
- Docs mention old resource names, metrics, namespaces, or image tags after change.
- Known limitations or failure modes are not documented.

## Cross-Reference Checks

For changed technical identifiers, search docs and runbooks for stale references:

- service/component name;
- namespace/cluster/environment;
- script/Make target;
- Terraform module/root;
- Helm chart/value name;
- image name/tag;
- metric/alert/dashboard name;
- secret name.

Use `ffgrep`/`grep` for both old and new identifiers from the diff.

## Report Requirements

`reports/docs-runbook-review.md` must include:

- docs/runbooks reviewed;
- technical changes that require docs;
- stale/missing/unsafe docs findings;
- examples checked;
- missing context and suggested documentation updates.
