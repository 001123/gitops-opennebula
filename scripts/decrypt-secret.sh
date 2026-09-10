#!/usr/bin/env bash
set -euo pipefail

# Hướng dẫn sử dụng:
# ./scripts/decrypt-secret.sh path/to/secret.enc.yaml

if [ $# -lt 1 ]; then
  echo "Usage: $0 <file-to-decrypt.enc.yaml>"
  echo "Example: $0 apps/nginx-demo/base/secret.enc.yaml"
  exit 1
fi

INPUT_FILE="$1"

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File '$INPUT_FILE' không tồn tại!"
  exit 1
fi

# Thiết lập đường dẫn Age key nếu chưa có
if [ -z "${SOPS_AGE_KEY_FILE:-}" ]; then
  if [ -f "$HOME/.config/sops/age/keys.txt" ]; then
    export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
  elif [ -f "$HOME/Library/Application Support/sops/age/keys.txt" ]; then
    export SOPS_AGE_KEY_FILE="$HOME/Library/Application Support/sops/age/keys.txt"
  fi
fi

echo "🔓 Đang giải mã '$INPUT_FILE':"
echo "----------------------------------------"
sops --decrypt "$INPUT_FILE"
echo "----------------------------------------"
