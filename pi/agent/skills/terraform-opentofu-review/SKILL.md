---
name: terraform-opentofu-review
description: Reviews Terraform, OpenTofu, and Terragrunt infrastructure-as-code for safety, security, cost, state/backends, plans, provider pinning, IAM, networking, encryption, backups, and destructive changes. Reviews all affected roots/modules/environments, not only changed files.
compatibility: opencode
---

# Terraform / OpenTofu Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Skill

Never run `apply`, `destroy`, `import`, or state mutation commands. Plans must be non-mutating and must not require remote changes. If unsure, skip.

## Output

Write `reports/terraform-opentofu-review.md`.

## Full-Scope Rule

If a module, provider, backend, variable, output, lockfile, or environment file changes, review all roots/environments that consume it.

## Scope

- `*.tf`, `*.tfvars`, `*.tfvars.json`
- `.terraform.lock.hcl`
- `terragrunt.hcl`, `terragrunt.hcl.json`, `terragrunt/**`
- modules and environment directories
- CI jobs that run Terraform/OpenTofu/Terragrunt

## Discovery

```bash
mkdir -p reports

# IaC files
find . -path './.git' -prune -o \( -name '*.tf' -o -name '*.tfvars' -o -name '*.tfvars.json' -o -name '.terraform.lock.hcl' -o -name 'terragrunt.hcl' -o -name 'terragrunt.hcl.json' \) -type f -print 2>/dev/null | sort

# Likely roots
find . -path './.git' -prune -o -name '*.tf' -type f -print 2>/dev/null | xargs -n1 dirname 2>/dev/null | sort -u
find . -path './.git' -prune -o -name 'terragrunt.hcl' -type f -print 2>/dev/null | xargs -n1 dirname 2>/dev/null | sort -u

# Module/source/backend/provider references
grep -RInE "(^\s*(source|backend|provider|required_version|required_providers)\b|module \"|resource \"|data \"|role|policy|cidr|0\.0\.0\.0/0|publicly_accessible|force_destroy|prevent_destroy|deletion_protection|skip_final_snapshot|encrypted|kms_key|backup|retention)" . --include='*.tf' --include='*.hcl' 2>/dev/null | head -500
```

## Validation Commands

Run in each affected root where safe and initialized enough:

```bash
terraform fmt -check -recursive
terraform validate
```

For OpenTofu:

```bash
tofu fmt -check -recursive
tofu validate
```

For Terragrunt:

```bash
terragrunt hclfmt --terragrunt-check
terragrunt validate
```

Optional non-mutating plan only when safe and credentials/context are available:

```bash
terraform plan -refresh=false -lock=false -out=/tmp/pi-review.tfplan
# or
terragrunt plan -refresh=false -lock=false -out=/tmp/pi-review.tfplan
```

Do not run plan if it would require initialization, credentials, or remote state access that is unavailable or unsafe. Report skipped plans.

## Review Checks

### BLOCK / HIGH

- Validation/fmt fails in affected roots.
- Destructive/replacement changes without plan evidence or rollback/backup notes.
- State backend missing locking or mixes environments.
- Provider/module versions unpinned or floating in production-critical code.
- Public network exposure (`0.0.0.0/0`, public load balancer, public DB) without justification.
- IAM policies with broad `*` actions/resources without justification.
- Data stores missing encryption, backup, retention, deletion protection, or final snapshot safety.
- `force_destroy`, `skip_final_snapshot`, `deletion_protection = false`, or similar destructive flags on important resources.
- Secrets, private keys, tokens, or kubeconfigs in tfvars/state-related files.

### MED / LOW

- Missing ownership/tags/labels/cost allocation.
- Variables lack descriptions, validation, or safe defaults.
- Outputs expose sensitive values without `sensitive = true`.
- Modules have unclear interfaces or environment-specific assumptions.
- Generated resources not documented in runbooks.
- Cost-sensitive instance sizes, retention, or replicas changed without explanation.

## Consumer Mapping

For changed modules or shared variables, search for all consumers:

```bash
grep -RInE "source\s*=\s*\".*<module-or-path>|module \"" . --include='*.tf' --include='*.hcl' 2>/dev/null
```

Report every affected root/environment, including ones not changed in the diff.

## Report Requirements

`reports/terraform-opentofu-review.md` must include:

- roots/modules/environments reviewed;
- changed files used as triggers;
- full consumers reviewed beyond diff;
- validation/plan commands run and results;
- destructive, security, access, network, backup, and cost findings;
- skipped checks and why.
