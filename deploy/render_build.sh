#!/bin/bash
# 🛠️ اسکریپت بیلد وب برای Render (یا هر هاست استاتیک)
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.7}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "⬇️ دانلود Flutter $FLUTTER_VERSION ..."
  curl -sL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" | tar xJ
  export PATH="$PWD/flutter/bin:$PATH"
fi

flutter config --enable-web >/dev/null 2>&1 || true
flutter pub get
flutter build web --release --no-tree-shake-icons --no-wasm-dry-run

# رندر ممکن است publishPath را "public" نگه دارد — مطمئن می‌شویم هر دو مسیر سرو شوند
mkdir -p public
rm -rf public/*
cp -r build/web/. public/
echo "✅ بیلد وب آماده: build/web + public/"
