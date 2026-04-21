---
name: shorts-forge
description: AutoShorts-style pipeline from script to rendered MP4 output.
version: 1.0.0
metadata:
  openclaw:
    emoji: "🎬"
    requires:
      bins: ["ffmpeg", "python3"]
      env: ["OUTPUT_DIR"]
    primaryEnv: null
    compat:
      openclaw: full
      zeroclaw: partial
      picoclaw: unsupported
      nullclaw: unsupported
      nanobot: partial
      ironclaw: partial
    security_tier: L2
    tags: ["creative", "video", "ffmpeg", "shorts"]
---

# shorts-forge

## Purpose

Turn a plain-text script into a short-form vertical video (9:16, 1080×1920)
using locally installed `ffmpeg`. The pipeline covers:

1. Script validation and scene segmentation
2. Optional voice-over prompt generation for TTS tools (ElevenLabs, piper, etc.)
3. Background clip selection from a local asset library
4. ffmpeg assembly with text-overlay burn-in
5. MP4 output to `$OUTPUT_DIR`

No cloud rendering required. CUDA acceleration is used automatically when
`CUDA_VISIBLE_DEVICES` is set and `ffmpeg` was compiled with `h264_nvenc`.

## Runbook

1. **Pre-flight** — verify `ffmpeg` and `python3` are available.  
   Check `OUTPUT_DIR` is set and writable.  
   Optionally set `ASSET_DIR` (default: `~/.shorts-forge/assets/`) for background
   clips and music. Populate it with royalty-free `.mp4` clips before first use.

2. **Validate script** — run `scripts/validate-script.sh <script.txt>`:
   - Checks total word count (target: 60–90 words for a 30–45 s short)
   - Splits into scenes at blank lines; warns if any scene > 25 words
   - Emits `script.json` with `[{scene_id, text, duration_hint_s}]`

3. **Generate voice-over prompt** — the validate script prints a ready-to-paste
   TTS prompt for each scene. Paste into your TTS tool and save output as
   `voiceover.mp3` (optional but strongly recommended for viewer retention).

4. **Render** — run `scripts/render.sh <script.json> [voiceover.mp3]`:
   - Picks a background clip from `ASSET_DIR` randomly (or uses `--bg-clip`)
   - Burns in subtitle text per scene with `drawtext` filter
   - Adds `voiceover.mp3` if provided, otherwise leaves silent
   - Encodes with `h264_nvenc` (GPU) or `libx264` (CPU fallback)
   - Output: `$OUTPUT_DIR/short_<timestamp>.mp4`

5. **Review output** — open the MP4 before publishing. The script does not
   auto-upload to any platform.

## Stop conditions

1. Abort if `ffmpeg` is not in `PATH`.
2. Abort if `OUTPUT_DIR` is unset or not writable.
3. Abort if the script exceeds 200 words — likely not a short-form script.
4. Abort if `ASSET_DIR` has no `.mp4` clips and no `--bg-clip` override is given.
5. Never auto-upload to YouTube, TikTok, or Instagram — output is local only.
6. Do not process scripts with URLs or shell-expansion characters unless explicitly reviewed.

## Output format

### Script validation (`script.json`)
```json
[
  {"scene_id": 1, "text": "Ever wondered how caffeine actually works?", "duration_hint_s": 4},
  {"scene_id": 2, "text": "It blocks adenosine receptors, tricking your brain into staying alert.", "duration_hint_s": 6}
]
```

### Render summary (stdout)
```
🎬 shorts-forge render complete
Output   : /home/user/shorts/short_20260422_143012.mp4
Duration : 38 s  (target: 30–45 s ✓)
Resolution: 1080×1920 @ 30fps
Encoder  : h264_nvenc (GPU)
Scenes   : 5
Audio    : voiceover.mp3 mixed
```

## Example invocations

- `scripts/validate-script.sh myscript.txt` — validate and segment script
- `scripts/render.sh script.json voiceover.mp3` — render to MP4
- `scripts/render.sh script.json --bg-clip nature.mp4` — specify background
- "Validate my script and tell me if it's the right length."
- "Render a short from script.json using my voiceover file."
