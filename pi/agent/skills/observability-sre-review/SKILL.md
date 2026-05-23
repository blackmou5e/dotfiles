---
name: observability-sre-review
description: "Reviews observability and operability: PrometheusRule, ServiceMonitor, PodMonitor, Grafana dashboards, logging/tracing config, alert routing, runbook links, SLOs, post-deploy checks, metrics cardinality, and diagnosis readiness. Reviews full observability path for affected components."
compatibility: opencode
---

# Observability / SRE Review

Read shared rules first: `../_shared/devops-review-common.md`.

## Read-Only Skill

Do not change alerting, dashboards, or monitoring systems. Do not query production systems unless explicitly allowed. Inspect repository files and run local validation only.

## Output

Write `reports/observability-sre-review.md`.

## Full-Scope Rule

If a service, deployment, alert rule, dashboard, metric name, label, log format, or runbook changes, review the full observability path for affected components.

## Scope

- `PrometheusRule`, `ServiceMonitor`, `PodMonitor`, scrape config
- Alertmanager routing/receiver labels
- Grafana dashboards and dashboard provisioning
- logging/tracing config
- SLO/error-budget docs
- runbooks linked from alerts
- readiness/liveness checks and post-deploy verification docs

## Discovery

```bash
mkdir -p reports

find . -path './.git' -prune -o \( -iname '*prometheus*' -o -iname '*alert*' -o -iname '*grafana*' -o -iname '*dashboard*' -o -iname '*runbook*' -o -iname '*slo*' -o -iname '*servicelevel*' -o -iname '*logging*' -o -iname '*tracing*' \) -type f -print 2>/dev/null | sort

grep -RInE "^kind: (PrometheusRule|ServiceMonitor|PodMonitor|AlertmanagerConfig)|alert:|expr:|for:|severity:|runbook|dashboard|grafana|metrics_path|prometheus.io/scrape|livenessProbe|readinessProbe|startupProbe|trace|otel|opentelemetry|logLevel|json logs" . --include='*.yaml' --include='*.yml' --include='*.json' --include='*.md' 2>/dev/null | grep -v './.git/' | head -500
```

## Review Checks

### BLOCK / HIGH

- Critical new production component has no way to verify health after deploy.
- Paging alert lacks clear routing/severity or runbook when team policy requires it.
- Alert expression is obviously invalid or references removed/renamed metric/label.
- Dashboard/alert queries still reference old service/job/namespace labels after change.
- Logs may expose secrets or PII.
- Metrics label change creates high-cardinality risk in critical path.
- Readiness/liveness semantics conflict with alerting or rollout expectations.

### MED / LOW

- No dashboard coverage for golden signals: availability, latency, errors, saturation.
- Alert lacks `for:` duration or has noisy threshold without context.
- Runbook link missing, stale, or does not include verification/rollback steps.
- Alerts do not include owner/team/environment labels.
- New dependency lacks monitoring or failure-mode alert.
- Post-deploy verification commands are missing or vague.
- Logging format changes not documented for consumers.

## Local Validation

Run only if tools are available:

```bash
# JSON dashboards
python3 - <<'PY'
import glob, json
for p in glob.glob('**/*.json', recursive=True):
    if any(x in p.lower() for x in ['dashboard','grafana']):
        try:
            json.load(open(p))
            print('OK', p)
        except Exception as e:
            print('FAIL', p, e)
PY

# Prometheus rules, if promtool exists
find . -type f \( -iname '*rule*.yaml' -o -iname '*prometheus*.yaml' -o -iname '*alert*.yaml' \) 2>/dev/null | while read -r f; do
  command -v promtool >/dev/null 2>&1 && promtool check rules "$f" || true
 done
```

Report skipped validation if tools are missing.

## Consumer Mapping

For changed service names, metric names, labels, namespaces, or dashboard variables, search across:

- Prometheus rules;
- dashboards;
- runbooks;
- manifests/Helm values;
- docs and post-deploy checks.

Use `ffgrep`/`grep` to find old and new identifiers.

## Report Requirements

`reports/observability-sre-review.md` must include:

- affected components and full observability path reviewed;
- alerts/dashboards/runbooks found or missing;
- validation command results;
- cardinality, secret-in-log, stale-query, and runbook findings;
- skipped checks and missing context.
