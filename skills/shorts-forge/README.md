# shorts-forge 🎬

> AutoShorts-style pipeline: script → scenes → ffmpeg-rendered MP4.

## What it does

`shorts-forge` turns a plain-text script into a vertical short-form video
(1080×1920 @ 30fps). It validates the script length, segments it into scenes,
burns subtitle text over a background clip, mixes in an optional voice-over, and
writes the final MP4 to your configured output directory.

CUDA acceleration (`h264_nvenc`) is used automatically when available; falls back
to CPU `libx264` otherwise.

## Setup

```bash
# One-time install (checks ffmpeg, python3, creates asset dirs)
bash skills/shorts-forge/install.sh

# Required env vars
export OUTPUT_DIR="$HOME/shorts"

# Optional — point to your royalty-free clip library
export ASSET_DIR="$HOME/.shorts-forge/assets"

# Optional — enable GPU encoding
export CUDA_VISIBLE_DEVICES=0
```

## Quickstart

```bash
# 1. Write your script (60–90 words, scenes separated by blank lines)
cat > myscript.txt << 'EOF'
Ever wondered how caffeine actually works?

It blocks adenosine receptors in your brain, preventing you from feeling tired.

Within 30 minutes, dopamine and adrenaline surge — that's the buzz you feel.

But drink too late and you'll wreck your sleep. Caffeine has a 5-hour half-life.

Time your last cup before 2 pm for clean energy without the crash.
EOF

# 2. Validate and segment
bash skills/shorts-forge/scripts/validate-script.sh myscript.txt

# 3. Render (add voiceover.mp3 if you have TTS output)
bash skills/shorts-forge/scripts/render.sh script.json voiceover.mp3
```

## Directory contents

| File | Description |
|------|-------------|
| `SKILL.md` | Machine-readable metadata and runbook |
| `COMPAT.md` | Per-variant notes (GPU, ffmpeg requirements) |
| `install.sh` | Verify ffmpeg/python3, create asset directories |
| `scripts/validate-script.sh` | Word-count check, scene segmentation, emit `script.json` |
| `scripts/render.sh` | ffmpeg assembly — background clip + subtitles + audio → MP4 |

## Asset library

Populate `$ASSET_DIR` with royalty-free `.mp4` clips (15–60 s, vertical preferred).
Sources: Pexels Videos, Pixabay Video, or your own footage.  
`render.sh` selects a clip at random unless `--bg-clip` is specified.

## GPU vs CPU encoding

| Condition | Encoder | ~Render time (60 s short) |
|-----------|---------|--------------------------|
| CUDA available + nvenc | `h264_nvenc` | ~8 s |
| CPU only | `libx264 -preset fast` | ~45 s |

## Security tier: L2

Reads script and asset files from local disk. Writes MP4 to `OUTPUT_DIR`.
No network access required. Does not auto-upload to any platform.

