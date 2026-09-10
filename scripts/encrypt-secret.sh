#!/usr/bin/env bash
set -euo pipefail

# Hướng dẫn sử dụng:
# ./scripts/encrypt-secret.sh path/to/secret.yaml [path/to/output.enc.yaml]

if [ $# -lt 1 ]; then
  echo "Usage: $0 <file-to-encrypt> [output-file.enc.yaml]"
  echo "Example: $0 apps/nginx-demo/base/secret.yaml apps/nginx-demo/base/secret.enc.yaml"
  exit 1
fi

INPUT_FILE="$1"
if [ $# -ge 2 ]; then
  OUTPUT_FILE="$2"
else
  OUTPUT_FILE="${INPUT_FILE%.*}.enc.yaml"
fi

if [ ! -f "$INPUT_FILE" ]; then
  echo "Error: File '$INPUT_FILE' không tồn tại!"
  exit 1
fi

echo "🔐 Đang mã hóa '$INPUT_FILE' -> '$OUTPUT_FILE' bằng SOPS + Age..."
sops --encrypt "$INPUT_FILE" > "$OUTPUT_FILE"
echo "✅ Đã mã hóa thành công! Bạn có thể commit an toàn file '$OUTPUT_FILE' lên Git."
