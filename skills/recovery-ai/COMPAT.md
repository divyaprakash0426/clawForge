# Compatibility notes for recovery-ai

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | Reads `lift-log` SQLite or `coach-claw` JSONL natively. All computation is in-process Python. |
| ZeroClaw | full | `python3` and standard library are available. Both workout log formats supported. |
| PicoClaw | partial | Works for JSONL input (coach-claw). SQLite reads work on RPi 4+ but may be slow with large databases on RPi Zero. HRV CSV parsing is fine regardless. |
| NullClaw | unsupported | No shell execution. ACWR calculation can be done manually using the thresholds in SKILL.md. |
| NanoBot | full | Python-native; this is the ideal environment for extending the load model with additional metrics (e.g. sleep score, calories). |
| IronClaw | partial | Both `WORKOUT_LOG_PATH` and `HRV_SOURCE_PATH` files must be within the IronClaw readable-paths allowlist. Write to `~/.recovery-ai/` requires writable-paths entry. |

