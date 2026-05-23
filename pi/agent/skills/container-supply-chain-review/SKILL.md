---
name: container-supply-chain-review
description: Reviews Dockerfiles, image build config, werf image sections, base image pinning, non-root runtime, .dockerignore, secrets in layers, SBOM/signing, vulnerability scan integration, and image consumers. Reviews all affected images and consumers, not only changed files.
compatibility: opencode
---

# Container Supply Chain Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Skill

Do not build or push images unless the user explicitly asks. Do not log in to registries. Inspect files and run local linters only.

## Output

Write `reports/container-supply-chain-review.md`.

## Full-Scope Rule

If a base image, Dockerfile, `.dockerignore`, build script, werf image definition, or image tag convention changes, review all images and all downstream consumers that can be affected.

## Scope

- `Dockerfile`, `Dockerfile.*`
- `.dockerignore`
- `docker-compose*.yml`, `docker-compose*.yaml` when used for tooling/build
- build scripts and Make targets
- `werf.yaml` image build sections
- CI build/push jobs
- image references in Kubernetes/Helm/GitOps manifests

## Discovery

```bash
mkdir -p reports

find . -path './.git' -prune -o \( -name 'Dockerfile' -o -name 'Dockerfile.*' -o -name '.dockerignore' -o -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' -o -name 'werf.yaml' \) -type f -print 2>/dev/null | sort

grep -RInE "(^FROM |image:|docker build|docker push|buildah|kaniko|img |werf build|werf publish|trivy|grype|syft|cosign|slsa|sbom|provenance)" . 2>/dev/null | grep -v './.git/' | head -500

grep -RInE "(latest|--build-arg|ARG .*TOKEN|ARG .*SECRET|COPY .*\.env|ADD .*\.env|USER root|USER 0|chmod 777|curl .*[|] sh|wget .*[|] sh)" . --include='Dockerfile*' --include='*.sh' --include='*.yml' --include='*.yaml' 2>/dev/null | grep -v './.git/' | head -500
```

## Review Checks

### BLOCK / HIGH

- Base image or runtime image uses `latest` or unpinned mutable tag in production-critical path.
- Secrets/tokens copied into image layers or passed as build args likely to persist in history.
- Dockerfile fetches and executes remote scripts without pinning/checksum.
- Runtime runs as root without justification.
- `.dockerignore` missing and build context likely includes secrets, `.git`, local env files, or large artifacts.
- Image build/push pipeline lacks source-to-image traceability for deployable artifacts.
- Vulnerability scanning is absent for production images where team policy expects it.
- CI can publish image from untrusted branch or without tests.

### MED / LOW

- No digest pinning for critical base images.
- Multi-stage build could reduce attack surface but does not.
- Package manager caches and build tools remain in final image.
- No SBOM, signing, provenance, or attestation where expected.
- Image tag naming is inconsistent between build pipeline and deploy manifests.
- Build args are not documented or have unsafe defaults.

## Local Validation

Run only if installed and local:

```bash
# Dockerfile lint if hadolint is present
find . -name 'Dockerfile' -o -name 'Dockerfile.*' 2>/dev/null | while read -r f; do
  command -v hadolint >/dev/null 2>&1 && hadolint "$f" || true
 done

# YAML parse for docker compose if Python/YAML is available
python3 - <<'PY'
import glob, yaml
for p in glob.glob('docker-compose*.yml') + glob.glob('docker-compose*.yaml'):
    try:
        yaml.safe_load(open(p))
        print('OK', p)
    except Exception as e:
        print('FAIL', p, e)
PY
```

Report skipped validation if tools are unavailable.

## Consumer Mapping

Search image names/tags in:

- Helm values/templates;
- raw Kubernetes manifests;
- Argo/Flux applications;
- CI deploy commands;
- docs/runbooks.

If build config changed, verify deploy consumers still point to expected registry/repository/tag convention.

## Report Requirements

`reports/container-supply-chain-review.md` must include:

- images/build configs reviewed;
- downstream consumers reviewed beyond diff;
- lint/scanner evidence or skipped status;
- blockers/warnings for pinning, secrets, root runtime, build context, scan/signing, and provenance;
- assumptions and missing context.
