---
name: secrets-and-access-review
description: Reviews repo-wide secret handling, credentials, CI variable usage, Kubernetes Secret/ExternalSecret/SOPS/SealedSecret, IAM, RBAC, service accounts, kubeconfigs, and access control. Use for security/access-sensitive DevOps changes. Reviews consumers and permissions beyond changed files.
compatibility: opencode
---

# Secrets and Access Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Skill

Never print secret values. Never test credentials. Never call cloud APIs that mutate access or resources. Only report secret type, key/name, path, and line.

## Output

Write `reports/secrets-and-access-review.md`.

## Full-Scope Rule

If a secret source, service account, IAM/RBAC policy, CI variable usage, encryption config, or credential path changes, review all consumers and permissions in that domain.

## Scope

- repo-wide secret-like patterns
- CI variables and secret usage in pipelines
- Kubernetes `Secret`, `ExternalSecret`, `SealedSecret`, SOPS files
- Terraform IAM/RBAC/access resources
- Kubernetes RBAC and service accounts
- kubeconfig/cloud credential handling
- scripts that read/write secrets

## Secret Safety Reporting

When a potential secret is found:

- do not copy the value;
- show `path:line`, key name, and type only;
- redact value as `[REDACTED]`;
- distinguish real secret from placeholder/example when possible.

## Discovery

```bash
mkdir -p reports

# Secret-like keys; redact manually in report
grep -RInE "(password|passwd|secret|token|api[_-]?key|apikey|private[_-]?key|client[_-]?secret|access[_-]?key|refresh[_-]?token|auth[_-]?token)\s*[:=]" . 2>/dev/null \
  | grep -v './.git/' \
  | grep -viE "example|sample|placeholder|dummy|changeme|TODO" \
  | head -500

# Private keys / kubeconfigs / cloud creds
grep -RInE "(BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY|apiVersion: v1.*clusters:|aws_access_key_id|aws_secret_access_key|GOOGLE_APPLICATION_CREDENTIALS|AZURE_CLIENT_SECRET)" . 2>/dev/null \
  | grep -v './.git/' \
  | head -200

# Kubernetes secrets and access
grep -RInE "^kind: (Secret|ExternalSecret|SealedSecret|ServiceAccount|Role|ClusterRole|RoleBinding|ClusterRoleBinding)|serviceAccountName:|rbac.authorization.k8s.io|external-secrets.io|sops:|encrypted_regex|creation_rules" . --include='*.yaml' --include='*.yml' 2>/dev/null \
  | grep -v './.git/' \
  | head -500

# IAM policy broad access in IaC
grep -RInE "(Action\s*=\s*\[?\s*\"\*\"|Resource\s*=\s*\[?\s*\"\*\"|Effect\s*=\s*\"Allow\"|iam:PassRole|AdministratorAccess|cluster-admin|verbs:\s*\[.*\*|resources:\s*\[.*\*)" . --include='*.tf' --include='*.json' --include='*.yaml' --include='*.yml' 2>/dev/null \
  | grep -v './.git/' \
  | head -500
```

Prefer tools such as `gitleaks detect --no-git` or `trufflehog filesystem` only if installed and safe; redact output before reporting.

## Review Checks

### BLOCK / HIGH

- Real credential, token, private key, kubeconfig, or cloud secret committed in plaintext.
- CI prints or persists secrets in logs, artifacts, or caches.
- Kubernetes `Secret` with real sensitive data stored unencrypted in repo.
- SOPS/SealedSecret/ExternalSecret misconfigured so secret cannot decrypt/sync or targets wrong namespace.
- IAM/RBAC grants admin or wildcard access without justification.
- `cluster-admin` binding for workload service account without explicit approved reason.
- Service account token or kubeconfig used across environments without separation.
- Secret rotation/owner unknown for newly introduced production secret.

### MED / LOW

- Secret naming or ownership unclear.
- ExternalSecret lacks refresh interval/target policy expected by team.
- RBAC grants more verbs/resources than needed.
- Sensitive Terraform outputs missing `sensitive = true`.
- Scripts handle secrets without `set +x`, temp-file cleanup, or restrictive permissions.
- Docs mention secrets but not source of truth or rotation procedure.

## Consumer Mapping

For every changed or newly referenced secret/access object, find consumers:

```bash
grep -RInE "secretKeyRef|configMapKeyRef|envFrom|volumeMounts:|secretName:|serviceAccountName:|roleRef:|subjects:" . --include='*.yaml' --include='*.yml' 2>/dev/null | grep -v './.git/' | head -500
```

Map:

- secret source -> target Kubernetes Secret -> workload env/volume;
- IAM role/policy -> service account/user/job;
- CI variable -> job/script/deploy command.

## Report Requirements

`reports/secrets-and-access-review.md` must include:

- files and domains scanned;
- consumer/permission map beyond changed files;
- potential secret findings with redacted evidence;
- access-control findings;
- tools run/skipped;
- required remediation or verification steps.
