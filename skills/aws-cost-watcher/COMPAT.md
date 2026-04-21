# Compatibility notes for aws-cost-watcher

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Ideal for credentialed operator shells that already have Cost Explorer access and webhook delivery configured. |
| ZeroClaw | full | Works well in CI or remote admin hosts where AWS credentials are injected and daily digests are posted to chat tools. |
| PicoClaw | partial | Lightweight devices can read saved reports, but direct Cost Explorer queries and webhook fan-out are less comfortable on constrained ARM nodes. |
| NullClaw | unsupported | NullClaw targets do not ship the AWS CLI credential context required for Cost Explorer or webhook automation. |
| NanoBot | full | Strong fit for summarizing spend anomalies and Bedrock cost movement into human-readable daily digests. |
| IronClaw | partial | Sandboxing may block STS checks, Cost Explorer API calls, or outbound webhook delivery. |
