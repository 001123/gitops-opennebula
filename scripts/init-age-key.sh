#!/usr/bin/env bash
set -euo pipefail

KEY_DIR="$HOME/.config/sops/age"
KEY_FILE="$KEY_DIR/keys.txt"
MAC_DIR="$HOME/Library/Application Support/sops/age"

if [ -f "$KEY_FILE" ]; then
  echo "ℹ️ File Age key đã tồn tại tại: $KEY_FILE"
  grep "public key:" "$KEY_FILE" || true
  exit 0
fi

mkdir -p "$KEY_DIR"
if [ "$(uname)" == "Darwin" ]; then
  mkdir -p "$MAC_DIR"
fi

echo "🔑 Đang sinh cặp khóa Age mới..."
age-keygen -o "$KEY_FILE"
chmod 600 "$KEY_FILE"

if [ "$(uname)" == "Darwin" ]; then
  cp "$KEY_FILE" "$MAC_DIR/keys.txt"
  chmod 600 "$MAC_DIR/keys.txt"
fi

echo "✅ Sinh khóa thành công!"
grep "public key:" "$KEY_FILE" || true
echo "⚠️ Hãy nhớ cập nhật public key ở trên vào file .sops.yaml!"
