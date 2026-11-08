#!/usr/bin/env bash
# Play Store captures (1080x1920) of the real screens with fictional members, in EN / FR / ES,
# written to google_play/images/captures/. Needs the fonts of tool/fetch_screenshot_fonts.sh.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f test_store/fonts/NotoColorEmoji.ttf ] || tool/fetch_screenshot_fonts.sh
flutter test test_store --update-goldens
# The Play Console wants screenshots without transparency (24-bit PNG)
python3 -I - <<'PY'
from pathlib import Path
from PIL import Image
for path in Path("google_play/images/captures").rglob("*.png"):
    Image.open(path).convert("RGB").save(path, optimize=True)
    print(path)
PY
