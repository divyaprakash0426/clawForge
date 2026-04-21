# inbox-zero

## What it does

Retrieves unread email headers over IMAP, classifies them into priority buckets,
and produces a JSON triage summary without touching message bodies or mailbox state.

## Prerequisites

- `IMAP_HOST`, `IMAP_USER`, and `IMAP_PASS`
- `curl`, `jq`, and `python3` in PATH
- Gmail users should prefer an app password instead of a primary account password

## Security notes

- Credentials are read from the environment only.
- `IMAP_PASS` is never printed or written to disk.
- The workflow fetches headers only: `From`, `Subject`, `Date`, and `Message-ID`.
- No move, delete, or mark-as-read operations are performed.

## Mock mode

```bash
MOCK_MODE=1 skills/inbox-zero/scripts/run.sh
```

## Quick start

```bash
export IMAP_HOST=imap.gmail.com
export IMAP_USER=me@gmail.com
export IMAP_PASS=your-app-password
skills/inbox-zero/scripts/run.sh
```
