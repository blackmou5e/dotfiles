---
name: full-scope-regression-review
description: Reviews full affected DevOps domains, not only changed files, to catch regressions caused by shared templates, defaults, modules, includes, and environment overlays. Use after repository-scope-discovery in every default DevOps review.
compatibility: opencode
---

# Full-Scope Regression Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Purpose

Make the selected review agents examine complete affected systems instead of only changed files. This catches regressions in untouched files caused by shared values, modules, CI includes, defaults, overlays, or generated output.

## Output

Write `reports/full-scope-regression-review.md`.

## Inputs

Use:

- `reports/repository-scope-discovery.md` when available;
- `reports/scope-inventory.json` when available;
- changed files from git as fallback;
- repository file inventory if discovery report is missing.

## Review Workflow

1. Identify changed files and selected domains.
2. For each domain, map changed files to full consumers:
   - Helm values/template -> all chart renders and environments using that value/template.
   - CI include/template -> all jobs/pipelines consuming it.
   - Terraform module -> all roots/environments using that module.
   - Kustomize base -> all overlays consuming the base.
   - Docker base/build script -> all images and deployments using the image.
   - Script/helper -> all Make targets, CI jobs, cron jobs, or docs invoking it.
   - Secret/RBAC/IAM file -> all identities, service accounts, bindings, and consumers.
   - Alert/dashboard metric label -> all alerts, dashboards, and runbooks using it.
3. Search for old and new names, variables, labels, image names, namespaces, module paths, and script entry points repo-wide.
4. Report cross-file inconsistencies and stale references.
5. Tell downstream specialized agents exactly what full scope to review.

## Useful Commands

```bash
# Changed files and touched identifiers
git diff --name-only origin/main...HEAD 2>/dev/null || git diff --name-only HEAD~1...HEAD 2>/dev/null || true
git diff --unified=0 origin/main...HEAD 2>/dev/null || git diff --unified=0 HEAD~1...HEAD 2>/dev/null || true

# Common regression patterns
grep -RInE "TODO|FIXME|deprecated|legacy|old-|staging|production|prod|namespace|image:|tag:|module|source\s*=|include:|uses:|run:|script:" . 2>/dev/null | grep -v './.git/' | head -500

# Find references to changed filenames without extension as fallback
for f in $(git diff --name-only 2>/dev/null | head -100); do
  base=$(basename "$f")
  stem="${base%.*}"
  [ -n "$stem" ] && grep -RIn -- "$stem" . 2>/dev/null | grep -v './.git/' | head -50
 done
```

Prefer `ffgrep` for large repositories.

## Findings to Look For

- Renamed variable used in one environment but not another.
- Updated default value that breaks untouched overlays.
- CI template changed but only one consumer tested.
- Terraform module interface changed but not all consumers updated.
- Image tag/build convention changed but deployment manifests still reference old tags.
- RBAC or service account changed but RoleBindings/subjects are stale.
- Monitoring labels changed but alerts/dashboards still query old labels.
- Runbook/deploy docs still describe previous commands or environment names.
- Duplicate pattern elsewhere in repository likely has the same issue.

## Report Requirements

`reports/full-scope-regression-review.md` must include:

- triggering files;
- full consumer map per selected domain;
- repo-wide reference searches performed;
- regression findings with evidence;
- downstream scope instructions for specialized agents;
- checks skipped due to missing context.
