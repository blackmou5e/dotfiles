---
name: cicd-pipeline-review
description: Reviews CI/CD pipelines for deployment safety, secret handling, protected production gates, rollback paths, version pinning, cache/artifact risks, and unsafe jobs. Use for GitLab CI, GitHub Actions, Jenkins, pipeline templates, and deploy scripts. Reviews full pipeline scope, not only changed files.
compatibility: opencode
---

# CI/CD Pipeline Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Skill

Never run deploy, apply, release, or cleanup jobs. Do not trigger pipelines. Only inspect files and run local non-mutating validators if available.

## Output

Write `reports/cicd-pipeline-review.md`.

## Full-Scope Rule

If any CI file, CI include, action, Jenkinsfile, or pipeline-called script changes, review the full pipeline graph and affected deploy jobs, not only changed YAML lines.

## Scope

- `.gitlab-ci.yml`, `.gitlab-ci*.yml`, `.gitlab-ci/**`, `.gitlab/**`
- `.github/workflows/**`, `.github/actions/**/action.yml`, `.github/actions/**/action.yaml`
- `Jenkinsfile`, `Jenkinsfile.*`, `jenkins/**`, `.jenkins/**`
- CI templates/includes referenced by those files
- scripts called from CI jobs
- Make targets called from CI jobs

## Discovery

```bash
mkdir -p reports

CI_FILES="$(find . \( -name '.gitlab-ci.yml' -o -name '.gitlab-ci*.yml' -o -path './.gitlab-ci/*' -o -path './.gitlab/*' -o -path './.github/workflows/*' -o -path './.github/actions/*/action.yml' -o -path './.github/actions/*/action.yaml' -o -name 'Jenkinsfile' -o -name 'Jenkinsfile.*' -o -path './jenkins/*' -o -path './.jenkins/*' \) -type f 2>/dev/null | sort)"
printf '%s\n' "$CI_FILES"

# Includes, job execution, and deploy commands
if [ -n "$CI_FILES" ]; then
  grep -En "(^\s*include:|uses:|image:|services:|script:|run:|stage:|environment:|only:|except:|rules:|when:|manual|protected|needs:|dependencies:|cache:|artifacts:|concurrency:|resource_group:|withEnv\(|input\(|parameters\{|helm |werf |kubectl |kustomize |terraform |tofu |terragrunt |ansible |docker |make |bash |sh |python )" $CI_FILES 2>/dev/null | head -500
fi
```

Use `ffgrep` for repeated searches in large repositories.

## Review Checks

### BLOCK / HIGH

- Production deploy can run from unprotected branch, fork, or untrusted event.
- Production deploy lacks manual approval or protected environment gate.
- Job uses `kubectl apply/delete`, `helm upgrade/install`, `werf converge`, `terraform apply/destroy`, or cloud mutation without plan/dry-run/approval path.
- Secrets are echoed, printed with `set -x`, passed in unsafe CLI args, written to artifacts, or stored in cache.
- Floating third-party actions/images in sensitive jobs (`@main`, `@master`, `latest`) without accepted policy.
- CI includes remote templates from mutable branches without pinning.
- Pipeline can deploy stale/unreviewed artifacts.
- Destructive cleanup jobs can run automatically or without environment guardrails.

### MED / LOW

- Missing pipeline concurrency control for deploys (`resource_group`, GitHub `concurrency`, Jenkins locking).
- Missing rollback job or rollback documentation.
- Cache keys are too broad and risk poisoning or cross-branch contamination.
- Artifacts expire too early/late or include unnecessary sensitive files.
- Dev/stage/prod variables are not clearly separated.
- Build/test/deploy dependencies are unclear or allow deploy without tests.
- Job names/stages make ownership or execution order hard to understand.

## Validation Commands

Run only if tools are installed and commands are local/read-only:

```bash
# YAML parse smoke test
python3 - <<'PY'
import glob, sys, yaml
for p in glob.glob('.gitlab-ci*.yml') + glob.glob('.github/workflows/*.yml') + glob.glob('.github/workflows/*.yaml'):
    try:
        yaml.safe_load(open(p))
        print('OK', p)
    except Exception as e:
        print('FAIL', p, e)
PY
```

If `python`/`yaml` is unavailable, skip and report.

## Pairing Rules

Trigger additional domain agents when CI invokes:

- Helm/werf -> `helm-chart-review`
- Terraform/OpenTofu/Terragrunt -> `terraform-opentofu-review`
- Docker/werf image build -> `container-supply-chain-review`
- Kubernetes/GitOps commands -> `kubernetes-gitops-review`
- scripts/Make targets -> `automation-script-review`
- secret manager/IAM commands -> `secrets-and-access-review`

## Report Requirements

`reports/cicd-pipeline-review.md` must include:

- CI files and includes reviewed;
- pipeline-called scripts reviewed or delegated;
- environments and deploy gates found;
- commands/validators run;
- blockers and warnings with evidence;
- skipped validations and why.
