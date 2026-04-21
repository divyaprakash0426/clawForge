---
name: tf-copilot
description: Terraform plan triager with compliance-aware fix suggestions.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🏗️"
    requires:
      bins: ["terraform", "checkov", "tfsec", "aws", "jq"]
      env: ["AWS_PROFILE", "AWS_REGION"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L3
    tags: ["devops", "terraform", "aws", "compliance"]
---

# tf-copilot

## Purpose

Terraform plan triager with compliance-aware fix suggestions.

## Runbook

1. Run `scripts/plan.sh [PLAN_FILE]` — if no `PLAN_FILE` is given, it runs `terraform plan -out=tf.plan && terraform show -json tf.plan` in the current directory and writes the JSON output to `tf-plan.json`.
2. Parse the plan JSON to extract resources to add, change, destroy, plus provider version constraints.
3. If the plan contains a destroy count greater than `0`, emit a prominent warning and list affected resource addresses.
4. Run `scripts/lint.sh` to invoke `checkov` and `tfsec` when they are available; collect the normalized findings into `tf-findings.json`.
5. Produce a markdown report via `scripts/report.sh` summarizing the plan diff table, compliance findings (HIGH / MEDIUM / LOW counts), and recommended fixes.
6. Never apply the plan — this skill is read-only analysis only.

## Stop conditions

1. Abort if `terraform` is missing.
2. Abort if the working directory has no `.tf` files and no `PLAN_FILE` is given.
3. Abort if a plan contains more than 10 destroys without an explicit `--allow-destroy` flag to `plan.sh`.
4. Abort if `aws` CLI credentials are not configured when the plan targets AWS resources.

## Output format

- `tf-plan.json` — raw `terraform show -json` output
- `tf-findings.json` — normalized `checkov` / `tfsec` findings
- Console: markdown report with a plan diff table and fix suggestions

## Example invocations

- `bash skills/tf-copilot/scripts/plan.sh`
- `bash skills/tf-copilot/scripts/plan.sh my-saved.plan.json`
- `bash skills/tf-copilot/scripts/lint.sh`
- `bash skills/tf-copilot/scripts/report.sh tf-plan.json tf-findings.json`
- "Analyze my terraform plan and tell me what will be destroyed."
