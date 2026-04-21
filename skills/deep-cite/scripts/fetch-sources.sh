#!/usr/bin/env bash
set -euo pipefail

SOURCES_FILE="${1:-}"
: "${SOURCE_DIR:?deep-cite fetch: set SOURCE_DIR}"

if [ -z "$SOURCES_FILE" ] || [ ! -f "$SOURCES_FILE" ]; then
  echo "deep-cite fetch: usage: fetch-sources.sh sources.txt" >&2
  exit 1
fi

mkdir -p "$SOURCE_DIR"

SOURCE_DIR="$SOURCE_DIR" SOURCES_FILE="$SOURCES_FILE" python3 - <<'PY'
import json
import os
import pathlib
import subprocess

source_dir = pathlib.Path(os.environ["SOURCE_DIR"])
sources_file = pathlib.Path(os.environ["SOURCES_FILE"])
urls = [line.strip() for line in sources_file.read_text(encoding="utf-8").splitlines() if line.strip() and not line.strip().startswith("#")]
if not urls and os.environ.get("MOCK_MODE") != "1":
    raise SystemExit("deep-cite fetch: no URLs found in sources file.")

mock_mode = os.environ.get("MOCK_MODE") == "1"
results = []
fetched = 0


def sample_html(url: str, index: int) -> str:
    return (
        f"<html><body><h1>Source {index}</h1>"
        f"<p>According to analysts, the study demonstrated a measurable quality gain for source-aware workflows.</p>"
        f"<p>Researchers reported that transparent citations improved operator trust in generated summaries.</p>"
        f"<p>Background text without claim markers remains available for context.</p>"
        f"<p>Original URL: {url}</p></body></html>"
    )


for index, url in enumerate(urls or ["https://example.test/mock-source"], start=1):
    file_name = f"source-{index:03d}.html"
    target = source_dir / file_name
    status = "fetched"
    if mock_mode:
        target.write_text(sample_html(url, index), encoding="utf-8")
        fetched += 1
    else:
        completed = subprocess.run(
            [
                "curl",
                "--location",
                "--silent",
                "--show-error",
                "--fail",
                "--max-time",
                os.environ.get("FETCH_TIMEOUT", "45"),
                url,
            ],
            capture_output=True,
            text=True,
        )
        if completed.returncode != 0:
            status = f"failed:{completed.stderr.strip() or completed.returncode}"
        else:
            target.write_text(completed.stdout, encoding="utf-8")
            fetched += 1
    results.append({"url": url, "source_file": file_name, "status": status})

(source_dir / "source-map.json").write_text(json.dumps(results, indent=2), encoding="utf-8")

if fetched == 0:
    print(json.dumps(results, indent=2))
    raise SystemExit("deep-cite fetch: all source fetches failed.")

print(
    json.dumps(
        {
            "sources_requested": len(results),
            "sources_fetched": fetched,
            "source_dir": str(source_dir),
            "source_map": str(source_dir / "source-map.json"),
        },
        indent=2,
    )
)
PY
