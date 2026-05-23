---
name: change-readiness-review
description: "Reviews production readiness of a DevOps change: reason, acceptance criteria, deploy plan, rollback plan, migration safety, backups, canary/feature flags, maintenance windows, stakeholder impact, and post-deploy checks. Reviews whole deploy/rollback path, not only changed docs."
compatibility: opencode
---

# Change Readiness Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Skill

Do not deploy, rollback, migrate, or modify infrastructure. Review evidence in repository/MR context and report missing readiness items.

## Output

Write `reports/change-readiness-review.md`.

## Full-Scope Rule

Review the whole deploy, rollback, monitoring, backup, and blast-radius path for the affected service/environment, not only changed readiness docs.

## Scope

- MR/PR description if available from user context
- README/docs/runbooks/ADRs
- migration scripts and deployment scripts
- CI deploy/rollback jobs
- backup/restore procedures
- feature flags/canary configuration
- post-deploy verification steps

## Discovery

```bash
mkdir -p reports

find . -path './.git' -prune -o \( -iname 'README*' -o -path './docs/*' -o -iname '*RUNBOOK*' -o -path './runbooks/*' -o -path './adr/*' -o -iname '*migration*' -o -iname '*rollback*' -o -iname '*backup*' -o -iname '*restore*' -o -iname '*deploy*' \) -type f -print 2>/dev/null | sort

grep -RInE "(rollback|backup|restore|migration|migrate|canary|blue.?green|feature.?flag|maintenance|downtime|post.?deploy|smoke.?test|verification|acceptance|SLO|runbook|incident|owner|stakeholder|blast.?radius)" . 2>/dev/null | grep -v './.git/' | head -500
```

## Readiness Checks

### BLOCK / HIGH

- Production-impacting change lacks rollback plan or rollback is clearly impossible without documented mitigation.
- Destructive data/IaC change lacks backup/restore evidence.
- Migration can cause downtime/data loss and has no ordering/rollback/safety notes.
- Deploy path unclear or missing for production change.
- Post-deploy verification absent for critical service/infrastructure change.
- Change requires maintenance window/stakeholder notice but none is documented.
- Blast radius includes shared platform, networking, IAM, state storage, or cluster-level resources without explicit risk handling.

### MED / LOW

- Acceptance criteria are vague or missing.
- Canary/progressive rollout not considered for risky change.
- Rollback steps exist but are not tested or lack owner/context.
- Monitoring/alerts after deploy not linked.
- Environment-specific differences are not documented.
- Docs do not explain why the change is needed.

## Evidence Sources

Use these sources before declaring readiness missing:

- User-provided MR/PR text;
- `review-summary.md` and specialized reports;
- CI/CD deploy and rollback jobs;
- runbooks/docs;
- migration/readiness scripts;
- Helm/Terraform/Kubernetes changes indicating blast radius.

If MR/PR description is unavailable, mark it as missing context rather than assuming it does not exist.

## Report Requirements

`reports/change-readiness-review.md` must include:

- affected services/environments;
- deployment path evidence;
- rollback path evidence;
- backup/migration safety evidence;
- post-deploy verification evidence;
- production/blast-radius assessment;
- blockers/warnings and missing context.
