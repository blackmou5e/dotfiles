---
name: helm-chart-review
description: |
  Automated review of Helm charts for safety, quality, and compliance. Reviews `.helm/` plus CI files that set Helm/werf render variables.
  Use for "review helm charts", "check helm", "lint helm", or "review kubernetes manifests".
  This skill only reads and analyzes — never modifies any files.
compatibility: opencode
---

## Read-Only Skill

**This skill is read-only.** It must NEVER:
- Edit, modify, or delete any files
- Create new files (except the mandatory `report.md`)
- Run any fix commands
- Apply any changes to charts or configuration

It only reads, analyzes, and writes findings to `report.md`.

## Review Scope

Primary review target: Helm/werf chart files under `.helm/`.

Supporting render-context target: CI pipeline files that define variables or commands used to render/deploy charts:
- GitLab CI: `.gitlab-ci.yml`, `.gitlab-ci*.yml`, `.gitlab-ci/`, `.gitlab/`
- GitHub Actions: `.github/workflows/`, `.github/actions/**/action.yml`, `.github/actions/**/action.yaml`
- Jenkins: `Jenkinsfile`, `Jenkinsfile.*`, `jenkins/`, `.jenkins/`

Read CI files only to discover chart-rendering context:
- Helm/werf commands (`helm template`, `helm lint`, `helm upgrade`, `helm install`, `werf render`, `werf converge`)
- Values files passed with `-f` / `--values`
- Overrides passed with `--set`, `--set-string`, `--set-file`
- Environment variables used by chart rendering (`WERF_*`, `HELM_*`, `KUBE_*`, `CI_ENVIRONMENT_NAME`, `ENVIRONMENT`, `DEPLOY_ENV`, release/namespace/image tag variables)
- Environment matrices or jobs that map to dev/stage/prod rendering

Do not perform a general CI/CD audit. Report CI findings only when they affect chart rendering, deployment safety, or hardcoded render secrets.

**Always use `codesearch` tool** for any Helm/Kubernetes related questions. Search for:
- Helm best practices, template functions, and common patterns
- Kubernetes manifest best practices (resource limits, probes, labels)
- SecurityContext configurations and examples
- Helm values.yaml patterns and conventions
- **Operator-specific documentation** (CNPG, werf, Deckhouse, Prometheus Operator, ArgoCD, etc.)

## Chart Discovery

**Before running checks, fetch latest Helm/Kubernetes best practices:**

```
codesearch --query "helm chart best practices kubernetes" --tokensNum 3000
```

Find all Helm charts in `.helm/` directory:

```bash
find .helm -maxdepth 2 -name "Chart.yaml" -type f 2>/dev/null
```

Find CI files that may provide render variables:

```bash
CI_FILES="$(find . \( -name ".gitlab-ci.yml" -o -name ".gitlab-ci*.yml" -o -path "./.gitlab-ci/*" -o -path "./.gitlab/*" -o -path "./.github/workflows/*" -o -path "./.github/actions/*/action.yml" -o -path "./.github/actions/*/action.yaml" -o -name "Jenkinsfile" -o -name "Jenkinsfile.*" -o -path "./jenkins/*" -o -path "./.jenkins/*" \) -type f 2>/dev/null)"
printf '%s\n' "$CI_FILES"
```

### werf.yaml Detection

**Check for werf.yaml to determine render tool:**

```bash
# If werf.yaml exists in project root, use werf instead of helm lint
if [ -f "werf.yaml" ]; then
  echo "WERF: detected werf.yaml, using werf render --dev"
  RENDER_TOOL="werf"
else
  echo "WERF: not detected, using helm lint"
  RENDER_TOOL="helm"
fi
```

If `werf.yaml` is present:
- Use `werf render --dev --ignore-secret-key` instead of `helm lint`
- Skip helm-specific checks (Chart.yaml structure, helm globals)
- Focus on werf-specific validations (Images, werf configurations)

### Environment / Enablement Detection

**Detect which environments/charts need to be enabled:**

```bash
# Check for enablement patterns in Chart.yaml or values
grep -rnE "(enabled:|disable:|enabled\s*[:=])" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null | head -30

# Check CI files for Helm/werf render commands, values files, and variable overrides
if [ -n "$CI_FILES" ]; then
  grep -En "(helm (template|lint|upgrade|install)|werf (render|converge)|--set(-string|-file)?|--values|-f |variables:|env:|withEnv\(|environment\s*\{|WERF_|HELM_|KUBE_|CI_ENVIRONMENT_NAME|ENVIRONMENT|DEPLOY_ENV|VALUES_FILE|IMAGE_TAG|RELEASE|NAMESPACE)" $CI_FILES 2>/dev/null | head -80
fi
```

**Common enablement variables:**
- `ENABLE_<component>` or `<component>_enabled: true`
- `global.<component>.enabled`
- Environment-specific toggles

**Render-variable rules from CI:**
- Prefer the exact render command found in CI, adapted to read-only rendering (`helm template` or `werf render`) instead of deploy/apply commands.
- Carry over non-secret CI values, values files, `--set` flags, release names, namespaces, and environment names needed to render.
- If a required CI variable is secret or unavailable, use a safe placeholder only when needed to render, never print secret values, and list the assumed variable names in the report.
- If CI defines multiple environments/jobs, render each distinct environment/job combination that changes values or flags.

### Multi-Environment Rendering

For each environment/chart that needs enabling, render separately:

**If werf.yaml exists:**
```bash
# Render for each environment (dev, stage, prod)
for env in dev stage prod; do
  echo "=== Rendering: $env ==="
  werf render --dev --ignore-secret-key --env="$env" 2>&1
done

# Render with specific --set overrides to enable components
werf render --dev --ignore-secret-key --set "postgresql.enabled=true" --set "redis.enabled=true" 2>&1
```

**If using helm:**
```bash
# Render with --set to enable components
helm template .helm/<chart> --set "postgresql.enabled=true" --set "redis.enabled=true" 2>&1
```

**Render each chart/subchart separately.** Do not combine them.

## External Tools & Operators Detection

**This project uses:** werf, Deckhouse, CNPG Operator, and various Kubernetes operators.

### Detection Phase

Scan charts for known tools/operators:

```bash
# WERF detection
grep -rEn "(werf|flant)" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null | head -20

# Deckhouse detection
grep -rEn "(deckhouse|d8|node-manager|mcm)" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null | head -20

# CNPG Operator (CloudNativePG)
grep -rEn "(cloudnativepg|cnpg|postgresql\.cnpg\.io)" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null | head -20

# Common operators detection
grep -rEn "(prometheus-operator|argocd|istio|cert-manager|external-dns|nginx-ingress|velero|rook|longhorn)" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null | head -50

# Image registry patterns (often reveal the tool)
grep -rn "image:" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null | grep -oE "(registry\..+|/[^/]+:)" | sort -u | head -30
```

### Documentation Lookup Rules

For each detected tool, follow this logic:

**If version is PINNED (e.g., `v1.2.3`, `1.2.3`):**
- Use `codesearch` to find that specific version's docs and CRD specs
- Use `webfetch` to fetch operator documentation

**If using `latest` or no version:**
- Use `codesearch` to find latest version
- Flag as WARN: version not pinned

### Tool-Specific Documentation URLs

| Tool | Documentation |
|------|---------------|
| CNPG Operator | https://cloudnative-pg.io/documentation/ |
| werf | https://werf.io/documentation/ |
| Deckhouse | https://deckhouse.io/ |
| Prometheus Operator | https://prometheus-operator.dev/ |
| ArgoCD | https://argo-cd.readthedocs.io/ |
| Istio | https://istio.io/latest/docs/ |

### Version Currency Check

After detection, check if pinned versions are current:

```bash
# Example: CNPG
codesearch --query "cloudnativepg postgres operator latest version 2026" --tokensNum 3000
```

**WARN if:** pinned version is more than 2 major versions behind latest
**INFO if:** using latest tag (recommend pinning)

## Quality Gates

The review runs these checks in order. **FAIL** stops immediately. **WARN** continues.

### FAIL Checks (blocks merge)

1. **Lint Check** — must render without errors:
   - If `werf.yaml` exists:
     - For each environment found in charts or CI: `werf render --dev --ignore-secret-key --env=dev`
     - For each enabled component found in charts or CI: `werf render --dev --ignore-secret-key --set <component>.enabled=true`
     - Include CI-derived non-secret flags such as `--values`, `--set`, `--namespace`, and `--release` when they are required to reproduce rendering.
   - Otherwise: `helm lint ".helm/<chart-name>" 2>&1`
     - Also run `helm template` with CI-derived values/flags when CI contains the deploy/render command.

2. **No `latest` image tags** — grep for `:latest`:
   ```bash
   grep -rn ":latest" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null
   ```

3. **No hardcoded secrets** — grep for secret-like patterns:
   ```bash
   grep -rEn "(password|secret|token|api.key|apikey)\s*[:=]\s*['\"]" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null | grep -v "values\.yaml\|example\|placeholder\|TODO"

   if [ -n "$CI_FILES" ]; then
     grep -En "(password|secret|token|api.key|apikey)\s*[:=]\s*['\"]" $CI_FILES 2>/dev/null | grep -v "example\|placeholder\|TODO"
   fi
   ```

4. **No hostPath volumes** — grep for hostPath:
   ```bash
   grep -rn "hostPath:" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null
   ```

### WARN Checks (report only)

5. **Missing resource requests** — containers without `resources.requests`:
   ```bash
   grep -rEn "^\s+containers:" .helm/ -A 50 --include="*.yaml" --include="*.yml" | grep -B5 "^\s+containers:" | grep -v "requests:" | grep -E "^\s+- name:" | head -20
   ```

6. **Missing memory limits** — containers without `resources.limits.memory`:
   ```bash
   grep -rEn "^\s+containers:" .helm/ -A 50 --include="*.yaml" --include="*.yml" | grep -v "limits:" | grep -E "memory" | head -20
   ```

7. **Missing probes** — no readinessProbe or livenessProbe:
   ```bash
   grep -rn "livenessProbe\|readinessProbe\|startupProbe" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null | wc -l
   ```
   If count is 0, flag all deployment/statefulset containers without probes.

8. **Missing required labels** — no `app:` and `component:` labels:
   ```bash
   grep -rn "labels:" .helm/ --include="*.yaml" --include="*.yml" -A 5 | grep -E "(app:|component:)" | wc -l
   ```

9. **Privileged pods** — securityContext with privileged: true:
   ```bash
   grep -rn "privileged:\s*true" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null
   ```

10. **Production replicas** — fewer than 3 replicas in prod context:
    ```bash
    grep -rn "replicas:" .helm/ --include="*.yaml" --include="*.yml" 2>/dev/null | grep -v "replicas: [3-9]" | head -10
    ```

### Chart Completeness Checks

11. **Chart.yaml completeness** — must have name, version, appVersion:
    ```bash
    for chart in $(find .helm -name "Chart.yaml" -type f); do
      echo "=== $(dirname "$chart") ==="
      grep -E "^(name|version|appVersion):" "$chart" 2>/dev/null || echo "MISSING FIELDS"
    done
    ```

12. **CRD handling** — check for crds/ directory with proper lifecycle:
    ```bash
    find .helm -name "crds" -type d 2>/dev/null && echo "CRDS: found" || echo "CRDS: not found"
    ```

## Review Workflow

1. Detect `werf.yaml` to determine render tool (werf vs helm)
2. Discover CI files that can provide Helm/werf render variables
3. Detect enabled environments/components that need --env or --set flags from charts and CI
4. Detect all tools/operators used in charts (werf, Deckhouse, CNPG, etc.)
5. Fetch documentation for each detected tool (use `codesearch` + `webfetch`)
6. Discover all charts in `.helm/`
7. Render each chart/subchart separately with appropriate chart + CI-derived flags
8. Run FAIL checks first (any failure = BLOCK) — using appropriate lint/render tool
9. Run WARN checks and collect findings
10. Run completeness checks + operator-specific checks
11. Generate summary report with tool version status and CI render context
12. Save report to `report.md`

**Always verify operator usage against current documentation.**

## Output Format

Generate the report and save to `report.md`:

```bash
cat > report.md << 'EOF'
## Helm Chart Review Results

### Tools & Operators Detected
| Tool | Version | Status | Latest | Action Required |
|------|---------|--------|--------|-----------------|
| CNPG Operator | v1.21.0 | BEHIND | v1.23.0 | Update recommended |
| werf | 1.2-latest | NOT PINNED | 1.2.5 | Pin to specific version |

### Charts Reviewed: N
- [x] chart-name-1
- [ ] chart-name-2 (FAILED: [reason])

### CI Render Context
| File | Variables/Flags Used | Environments |
|------|----------------------|--------------|
| .gitlab-ci.yml | --values values-prod.yaml, IMAGE_TAG | prod |

### FAIL Issues (blocking)
| Chart | Issue | Location |
|-------|-------|----------|
| name  | latest tag found | templates/deployment.yaml:23 |

### WARN Issues (recommend fix)
| Severity | Chart | Issue | Location |
|----------|-------|-------|----------|
| HIGH | name | No liveness probe | templates/deployment.yaml:15 |
| MED  | name | No resource requests | templates/deployment.yaml:20 |
| MED  | name | Operator version outdated | Chart.yaml:3 |

### Completeness
| Chart | Chart.yaml | CRDs | Status |
|-------|------------|------|--------|
| name  | OK | N/A | PASS |

### Summary
- FAIL: X issues (BLOCK)
- WARN: Y issues (recommend fixing)
- Operator versions: Z outdated
- PASS: charts reviewed
EOF
```

**Always write the report to `report.md` in the project root.**

## Review Specific Files

To review only specific charts:

```bash
REVIEW_CHARTS="chart1,chart2"
for chart in $(echo "$REVIEW_CHARTS" | tr ',' ' '); do
  echo "=== Reviewing: $chart ==="
  helm lint ".helm/$chart" 2>&1
done
```

## Notes

- Reviews `.helm/` plus CI files that define Helm/werf render variables
- CI files are render context, not a general CI/CD audit target
- Uses `helm lint` as baseline validation
- If `werf.yaml` detected: use `werf render --dev --ignore-secret-key` with `--env` and `--set` for each environment/component
- If CI defines Helm/werf commands, reproduce them as read-only rendering commands with the same non-secret values and flags
- Render each chart/subchart separately — do not combine
- Uses `--env=dev`, `--env=stage`, `--env=prod` for werf environments
- Uses `--set component.enabled=true` for enabling optional subcharts
- Uses CI-discovered `--values`, `--set`, namespace, release, and image tag variables when required to render
- Lists missing/assumed CI variables in `report.md` without exposing secret values
- Resource/probe checks parse YAML structure, not just string matching
- Production replicas check: warns if any Deployment has replicas < 3 (user should verify prod context)
- Detects and validates: werf, Deckhouse, CNPG Operator, and other Kubernetes operators
- Always fetch current documentation for detected tools before reviewing their manifests
- If version is pinned, search for that version's specific docs; if `latest`, warn and fetch latest docs
- Always saves report to `report.md`
- Always use fff and context7
