#!/bin/sh
# Krea 2 DirtyUncut — everything the worker image needs. The Dockerfile in your copy downloads this file
# from the original repo on every build, so fixes made there reach you with a rebuild.
set -eu
case "${CIVITAI_TOKEN:-}" in ""|PASTE_*) echo "ERROR: set CIVITAI_TOKEN at the top of the Dockerfile" >&2; exit 1;; esac

# file <dest> <url> <sha256>
file() {
  wget -q -O "$1" "$2"
  echo "$3  $1" | sha256sum -c - || { echo "ERROR: $1 changed upstream — wait for an update of the original repo, then rebuild" >&2; exit 1; }
}

# Krea2-SAT-DirtyRealism "DirtyUncut" fp8 (Civitai model 2796522 / version 3372523, Krea 2 Turbo fine-tune, 12.5GB)
file /comfyui/models/diffusion_models/krea2_dirtyuncut_fp8.safetensors \
  "https://civitai.com/api/download/models/3372523?type=Model&format=SafeTensor&fp=fp8&token=${CIVITAI_TOKEN}" \
  300b7758b8d7f163f1acd580c93b2d60829885c54e4f51753e398a84d97002e3
# Krea 2 text encoder (Qwen3-VL-4B fp8) and VAE — Comfy-Org repack, Krea 2 Community License
HF=https://huggingface.co/Comfy-Org/Krea-2/resolve/eb1eddd3983a54678545a9b2c178c5853b30f7be
file /comfyui/models/text_encoders/qwen3vl_4b_fp8_scaled.safetensors "$HF/text_encoders/qwen3vl_4b_fp8_scaled.safetensors" \
  54bd5144df0bbc25dd6ccadfcb826b521445a1b06ae5a42570bdd2974ca87094
file /comfyui/models/vae/qwen_image_vae.safetensors "$HF/vae/qwen_image_vae.safetensors" \
  a70580f0213e67967ee9c95f05bb400e8fb08307e017a924bf3441223e023d1f

# ComfyUI 0.34.0 (base image) → 0.39.0 — Krea 2 needs 0.37+. Install into /opt/venv (the one ComfyUI actually runs with).
cd /comfyui
git fetch --depth 1 https://github.com/Comfy-Org/ComfyUI.git tag v0.39.0
git checkout -f v0.39.0
uv pip install --python /opt/venv/bin/python -r requirements.txt "transformers>=4.50.3,<5" "huggingface-hub<1.0"
timeout 300 /opt/venv/bin/python main.py --quick-test-for-ci --cpu
