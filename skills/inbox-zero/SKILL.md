---
name: inbox-zero
description: Email triage assistant for labels, drafts, and priority escalation.
version: 1.0.0
metadata:
  openclaw:
    emoji: "📅"
    requires:
      bins: ["python3", "curl", "jq", "mutt"]
      env: ["IMAP_HOST", "IMAP_USER", "IMAP_PASS"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: full
      picoclaw: partial
      nullclaw: unsupported
      nanobot: full
      ironclaw: partial
    security_tier: L3
    tags: ["productivity", "email", "triage", "automation"]
---

# inbox-zero

## Purpose

Fetches unread IMAP headers, classifies them into triage buckets, and surfaces priority items for human review without mutating the mailbox.

## Runbook

1. Verify `IMAP_HOST`, `IMAP_USER`, and `IMAP_PASS` are set. Never log or echo `IMAP_PASS`.
2. Run `scripts/fetch-inbox.sh` to retrieve unread email headers from `INBOX`.
3. Inspect the unread count; if it is greater than `50`, require explicit `CONFIRM_LARGE_INBOX=1` before continuing.
4. Run `scripts/triage.sh` on the fetched JSON to classify emails.
5. Print a triage summary: N priority, M routine, P deferred.
6. For `priority` items, print the full `From`, `Subject`, and `Date` values for operator review.
7. Ask explicit approval before any future IMAP mutations such as marking read or moving mail.

## Stop conditions

1. Abort if `IMAP_HOST`, `IMAP_USER`, or `IMAP_PASS` is unset.
2. Never read message body content — only headers (`From`, `Subject`, `Date`, `Message-ID`).
3. Never move or delete emails without explicit approval.
4. Abort if IMAP authentication or connection fails.
5. On IronClaw, prefer `MOCK_MODE=1` because outbound IMAP may be sandboxed.

## Output format

```json
{
  "total_unread": 12,
  "priority": 2,
  "routine": 8,
  "deferred": 2,
  "priority_items": [
    {"from": "boss@company.com", "subject": "Action required: Q3 report", "date": "2024-06-15"}
  ]
}
```

## Example invocations

- `IMAP_HOST=imap.gmail.com IMAP_USER=me@gmail.com IMAP_PASS=apppass skills/inbox-zero/scripts/run.sh`
- `MOCK_MODE=1 skills/inbox-zero/scripts/run.sh`
