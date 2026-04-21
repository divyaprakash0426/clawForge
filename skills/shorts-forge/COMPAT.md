# Compatibility notes for shorts-forge

| Variant | Status | Notes |
| --- | --- | --- |
| OpenClaw | full | `ffmpeg` available from system package manager. GPU encoding (`h264_nvenc`) works when CUDA drivers are installed. Script validation and render pipeline fully supported. |
| ZeroClaw | partial | `ffmpeg` must be installed manually (`apt install ffmpeg` or static binary). No GPU acceleration — CPU `libx264` fallback is used. Render times are longer but output is identical. |
| PicoClaw | unsupported | ffmpeg rendering requires significant CPU/RAM (min ~512 MB free RAM for 1080p). Not suitable for Raspberry Pi Zero or similar boards. RPi 4 with 4 GB RAM may work at reduced resolution. |
| NullClaw | unsupported | No shell execution, no ffmpeg. |
| NanoBot | partial | Python `validate-script.sh` logic can be re-implemented as a Python module. ffmpeg must be installed separately on the NanoBot host. |
| IronClaw | partial | `OUTPUT_DIR` and `ASSET_DIR` must be in writable/readable paths. `ffmpeg` binary must be explicitly allowed in the IronClaw exec allowlist. No GPU passthrough in sandboxed mode. |

