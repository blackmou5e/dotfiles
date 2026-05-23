---
name: automation-script-review
description: Reviews DevOps automation scripts, shell scripts, Makefiles, Python/Go utilities, cron jobs, and pipeline-called helpers for idempotency, safety, quoting, dry-run support, error handling, retries, timeouts, and destructive command guardrails. Reviews callers and entry points beyond changed files.
compatibility: opencode
---

# Automation Script Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Skill

Do not execute scripts that may mutate infrastructure, delete data, deploy, or call cloud/cluster APIs. Static analysis and safe linters are allowed.

## Output

Write `reports/automation-script-review.md`.

## Full-Scope Rule

If a shared helper, Make target, cron script, or pipeline-called script changes, review all entry points and callers that can execute it.

## Scope

- `*.sh`, `*.bash`, shell snippets
- `Makefile`, `*.mk`
- Python/Go utility scripts used by DevOps workflows
- `scripts/**`, `bin/**`, `tools/**`, `hack/**`
- cron/job automation
- scripts invoked from CI/CD or runbooks

## Discovery

```bash
mkdir -p reports

find . -path './.git' -prune -o \( -path './scripts/*' -o -path './bin/*' -o -path './tools/*' -o -path './hack/*' -o -name '*.sh' -o -name '*.bash' -o -name 'Makefile' -o -name '*.mk' -o -name '*.py' -o -name '*.go' \) -type f -print 2>/dev/null | sort

grep -RInE "(rm -rf|kubectl (delete|apply|patch|replace|scale|rollout restart)|helm (upgrade|install|uninstall)|werf (converge|dismiss|cleanup)|terraform (apply|destroy|import|state)|tofu (apply|destroy|import|state)|aws .*delete|gcloud .*delete|az .*delete|set -x|curl .*[|] sh|wget .*[|] sh|sudo |chmod 777|mktemp|trap |timeout |retry|sleep )" . --include='*.sh' --include='*.bash' --include='Makefile' --include='*.mk' --include='*.py' 2>/dev/null | grep -v './.git/' | head -500

# callers from CI/docs/Makefiles
grep -RInE "(scripts/|bin/|tools/|hack/|make |bash |sh |python |go run)" .gitlab-ci.yml .gitlab-ci .github/workflows Jenkinsfile* jenkins .jenkins Makefile docs README* 2>/dev/null | head -500
```

## Review Checks

### BLOCK / HIGH

- Destructive commands (`rm -rf`, cloud delete, `kubectl delete`, `terraform destroy`, etc.) without environment guard, confirmation, dry-run, or allowlist.
- Script can run against production by default or with ambiguous context.
- Missing `set -e`/error handling causes failures to be ignored in deploy or migration path.
- Unquoted variables can delete or mutate wrong paths/resources.
- Secret values may be printed via `set -x`, `echo`, logs, or command args.
- Temp files containing secrets are not cleaned up or have weak permissions.
- Remote script execution (`curl | sh`) without pinning/checksum.

### MED / LOW

- Not idempotent; rerun may fail or duplicate resources.
- No timeout/retry/backoff for network/cloud operations.
- No structured logging or clear error messages.
- No `--dry-run`/preview mode for operations that change state.
- Make targets lack `.PHONY` or have surprising dependencies.
- Python/Go utility lacks tests or input validation.
- Cleanup trap missing for temporary resources.

## Local Validation

Run safe static tools if available:

```bash
# ShellCheck
find . -type f \( -name '*.sh' -o -name '*.bash' \) 2>/dev/null | while read -r f; do
  command -v shellcheck >/dev/null 2>&1 && shellcheck "$f" || true
 done

# Bash syntax only, no execution
find . -type f \( -name '*.sh' -o -name '*.bash' \) 2>/dev/null | while read -r f; do
  bash -n "$f" || true
 done

# Python syntax only, no execution
find . -type f -name '*.py' 2>/dev/null | while read -r f; do
  python3 -m py_compile "$f" || true
 done
```

Do not run project scripts unless proven read-only.

## Caller Mapping

For each changed script/helper, find:

- CI jobs invoking it;
- Make targets wrapping it;
- runbooks/docs instructing humans to run it;
- cron/job specs executing it;
- other scripts sourcing/importing it.

Review caller context to determine environment, permissions, and blast radius.

## Report Requirements

`reports/automation-script-review.md` must include:

- scripts and callers reviewed;
- static analysis commands/results;
- destructive-path findings;
- idempotency/error-handling/secret-handling findings;
- skipped checks and why.
