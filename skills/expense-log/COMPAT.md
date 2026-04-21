# Compatibility notes for expense-log

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Python3 + sqlite3 stdlib; no extra packages. All import/categorise/report scripts work natively. |
| ZeroClaw | full | `python3` and `sqlite3` available in standard ZeroClaw image. All scripts supported. |
| PicoClaw | partial | Works on Raspberry Pi 4+. SQLite performance is fine for personal ledger sizes. CSV parsing works on RPi Zero but may be slow for large files (> 10 k rows). Consider splitting import into smaller batches. |
| NullClaw | unsupported | No shell execution. Import and categorisation can be done manually using the rules in `~/.expense-log/rules.json` as a reference. |
| NanoBot | full | Python-native; the categorisation logic is trivially extensible with ML classifiers (e.g. scikit-learn) for smarter auto-labelling. |
| IronClaw | partial | `INPUT_DIR` and `REPORT_DIR` must be in the IronClaw readable/writable paths allowlist. `~/.expense-log/` must also be allowed. No network access required — this skill is fully offline. |

