# Compatibility notes for tf-copilot

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Best fit for local Terraform workspaces where `terraform`, `jq`, compliance scanners, and AWS credentials are available together. |
| ZeroClaw | full | Strong CI / remote-shell fit when the runner can execute Terraform plans but must still stop before apply. |
| PicoClaw | partial | ARM boards can inspect saved plan JSON, but generating fresh plans and running `checkov` / `tfsec` may be slow or memory-heavy. |
| NullClaw | unsupported | NullClaw targets do not expose the full Terraform + AWS CLI toolchain needed for safe plan analysis. |
| NanoBot | full | Excellent for summarizing plan JSON and compliance output into an operator-friendly narrative without mutating infrastructure. |
| IronClaw | partial | Sandboxed runners can review exported plans, but cloud credential access and provider plugins are often restricted. |
