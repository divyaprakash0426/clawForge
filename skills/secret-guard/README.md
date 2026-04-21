# secret-guard

## What it does

`secret-guard` scans repositories and skill definitions for likely committed credentials, masks anything it finds, and produces a local markdown report with next-step guidance.

## Tool priority

1. `gitleaks`
2. `trufflehog`
3. Built-in regex fallback in `scan.sh`

## Quick start

```bash
bash skills/secret-guard/scripts/scan.sh .
bash skills/secret-guard/scripts/report.sh secret-findings.json
```

## Masking behavior

All findings are masked before they are written to disk or printed to the console. Values are truncated to the first 6 characters plus `***`.

## What to do when findings are found

- Rotate or revoke the credential first.
- Remove the secret from current files and, if necessary, from Git history.
- Add `.env`, `*.pem`, or other sensitive local files to `.gitignore`.
- Re-run `scan.sh` until the report is clean.
