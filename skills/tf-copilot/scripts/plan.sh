#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: plan.sh [--allow-destroy] [PLAN_FILE]

Analyze a Terraform plan without applying it.
- With no PLAN_FILE, runs `terraform plan -out=tf.plan` in the cwd.
- With PLAN_FILE, accepts either a JSON plan or a binary plan readable by `terraform show -json`.
EOF
}

allow_destroy=0
plan_input=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --allow-destroy)
      allow_destroy=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [ -n "$plan_input" ]; then
        echo "Only one PLAN_FILE may be provided." >&2
        exit 1
      fi
      plan_input="$1"
      shift
      ;;
  esac
done

for bin in terraform jq; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "tf-copilot requires $bin." >&2
    exit 1
  fi
done

if [ -n "$plan_input" ]; then
  if [ ! -f "$plan_input" ]; then
    echo "Plan file not found: $plan_input" >&2
    exit 1
  fi
  case "$plan_input" in
    *.json)
      if ! jq empty "$plan_input" >/dev/null 2>&1; then
        echo "Plan JSON is not valid: $plan_input" >&2
        exit 1
      fi
      if [ "$plan_input" != "tf-plan.json" ]; then
        cp "$plan_input" tf-plan.json
      fi
      ;;
    *)
      terraform show -json "$plan_input" > tf-plan.json
      ;;
  esac
else
  if ! compgen -G '*.tf' >/dev/null; then
    echo "No .tf files found in the current directory. Provide PLAN_FILE or run inside a Terraform workspace." >&2
    exit 1
  fi
  terraform plan -out=tf.plan >/dev/null
  terraform show -json tf.plan > tf-plan.json
fi

if ! jq empty tf-plan.json >/dev/null 2>&1; then
  echo "Unable to parse tf-plan.json." >&2
  exit 1
fi

aws_in_plan="$(jq -r '([
  .resource_changes[]? |
  select(((.type // "") | startswith("aws_")) or ((.provider_name // "") | test("aws")))
] | length) > 0 or ([
  .configuration.provider_config? |
  to_entries[]? |
  select(((.value.full_name // .value.name // .key) | tostring | test("aws")))
] | length) > 0' tf-plan.json)"

if [ "$aws_in_plan" = "true" ]; then
  if [ -z "${AWS_REGION:-}" ]; then
    echo "AWS_REGION must be set when the plan targets AWS resources." >&2
    exit 1
  fi
  if ! command -v aws >/dev/null 2>&1; then
    echo "aws CLI is required when the plan targets AWS resources." >&2
    exit 1
  fi
  if ! aws sts get-caller-identity >/dev/null 2>&1; then
    echo "AWS credentials are not configured for the targeted AWS plan." >&2
    exit 1
  fi
fi

add_count="$(jq '[.resource_changes[]? | select((.change.actions // []) | index("create"))] | length' tf-plan.json)"
change_count="$(jq '[.resource_changes[]? | select((.change.actions // []) | index("update"))] | length' tf-plan.json)"
destroy_count="$(jq '[.resource_changes[]? | select((.change.actions // []) | index("delete"))] | length' tf-plan.json)"
type_breakdown="$(jq -r '[.resource_changes[]? | (.type // "unknown")] | group_by(.) | map({type: .[0], count: length}) | .[]? | "| `\(.type)` | \(.count) |"' tf-plan.json)"
provider_lines="$(jq -r '[.configuration.provider_config? | to_entries[]? | {provider: (.value.full_name // .value.name // .key), constraint: (.value.version_constraint // "unspecified")}] | unique_by(.provider + "|" + .constraint) | .[]? | "| `\(.provider)` | `\(.constraint)` |"' tf-plan.json)"
destroy_lines="$(jq -r '.resource_changes[]? | select((.change.actions // []) | index("delete")) | "- `\(.address)`"' tf-plan.json)"

printf '## tf-copilot plan summary

'
printf '| Action | Count |
| --- | ---: |
'
printf '| Add | %s |
' "$add_count"
printf '| Change | %s |
' "$change_count"
printf '| Destroy | %s |
' "$destroy_count"

printf '
### Resource type breakdown

'
printf '| Resource type | Count |
| --- | ---: |
'
if [ -n "$type_breakdown" ]; then
  printf '%s
' "$type_breakdown"
else
  printf '| _none_ | 0 |
'
fi

printf '
### Provider constraints

'
printf '| Provider | Constraint |
| --- | --- |
'
if [ -n "$provider_lines" ]; then
  printf '%s
' "$provider_lines"
else
  printf '| _unknown_ | `unspecified` |
'
fi

if [ "$destroy_count" -gt 0 ]; then
  printf '
> WARNING: %s resource(s) scheduled for destroy.
' "$destroy_count"
  if [ -n "$destroy_lines" ]; then
    printf '%s
' "$destroy_lines"
  fi
fi

if [ "$destroy_count" -gt 10 ] && [ "$allow_destroy" -ne 1 ]; then
  echo "Refusing to continue: plan contains more than 10 destroys. Re-run with --allow-destroy after explicit review." >&2
  exit 1
fi
