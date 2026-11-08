#!/usr/bin/env bash
# Emoji and fallback fonts for the Play Store captures (test_store/), not shipped with the app:
# on a phone, the system supplies them. Kept out of Git (25 MB).
set -euo pipefail
cd "$(dirname "$0")/../test_store/fonts"
curl -sfL -o NotoColorEmoji.ttf https://raw.githubusercontent.com/google/fonts/main/ofl/notocoloremoji/NotoColorEmoji-Regular.ttf
curl -sfL -o NotoSans.ttf https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSans/hinted/ttf/NotoSans-Regular.ttf
curl -sfL -o NotoSansSymbols2.ttf https://github.com/notofonts/notofonts.github.io/raw/main/fonts/NotoSansSymbols2/hinted/ttf/NotoSansSymbols2-Regular.ttf
ls -la
