---
name: kube-scout
description: Audit Kubernetes manifests for unsafe defaults, missing limits, and weak image pinning.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🛠️"
    requires:
      bins: ['python3']
      env: []
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L1
    tags: ['devops', 'kubernetes', 'manifests', 'audit']
---

# kube-scout

## Purpose

Review Kubernetes YAML before apply and surface risky workload settings in a compact report.

## Runbook

1. Point the skill at one or more manifest files or directories containing YAML.
2. Run `scripts/audit.py` to inspect pod specs, init containers, volumes, and top-level networking flags.
3. Prioritize findings that affect runtime safety first: privileged containers, hostPath mounts, and host networking.
4. Treat the report as a pre-apply review; do not mutate manifests automatically.

## Stop conditions

1. Abort if PyYAML is unavailable, because partial parsing is riskier than no report.
2. Abort if the target variant is marked unsupported.
3. Abort before approving deployment of a manifest that still has unresolved critical findings.

## Output format

- JSON summary of resources scanned
- Critical and warning findings with file, resource, and reason
- Counts for missing limits, privileged containers, and weak image pinning

## Example invocations

- `python3 skills/kube-scout/scripts/audit.py k8s/`
- `python3 skills/kube-scout/scripts/audit.py deployment.yaml --markdown`
