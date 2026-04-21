# tf-copilot

## What it does

`tf-copilot` is a read-only Terraform triage helper. It builds or ingests a plan, summarizes adds / changes / destroys, runs compliance scanners when present, and produces a markdown report with concrete remediation hints.

## Quick start

```bash
bash skills/tf-copilot/scripts/plan.sh
bash skills/tf-copilot/scripts/lint.sh
bash skills/tf-copilot/scripts/report.sh tf-plan.json tf-findings.json
```

## Required tools

- `terraform` — generate or inspect plans
- `jq` — plan parsing and report generation
- `aws` — credential check when the plan targets AWS resources
- `checkov` — optional but recommended compliance linting
- `tfsec` — optional but recommended Terraform security linting

## Sample output

```md
## tf-copilot report

| Action | Count |
| --- | ---: |
| Add | 3 |
| Change | 1 |
| Destroy | 1 |

> WARNING: 1 resource(s) scheduled for destroy.
- `aws_security_group.legacy_ingress`

### Compliance summary
| Severity | Count |
| --- | ---: |
| HIGH | 1 |
| MEDIUM | 2 |
| LOW | 0 |
```

## Security notes

- This skill is **L3** because it inspects infrastructure plans that may target credentialed AWS accounts.
- `plan.sh` and `run.sh` never call `terraform apply`.
- Large destroy plans are blocked unless the operator explicitly passes `--allow-destroy`.
- AWS-targeting plans require working CLI credentials so the operator does not reason about stale or mismatched account context.
