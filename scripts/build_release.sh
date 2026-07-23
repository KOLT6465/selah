#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="${1:-$ROOT/outputs}"
DERIVED="$ROOT/work/DerivedData"

mkdir -p "$OUTPUT"
xcodebuild -project "$ROOT/Selah.xcodeproj" -scheme Selah -configuration Release -derivedDataPath "$DERIVED" CODE_SIGNING_ALLOWED=NO build
APP="$DERIVED/Build/Products/Release/Selah.app"
codesign --force --deep --sign - --entitlements "$ROOT/Selah/Selah.entitlements" "$APP"
rm -rf "$OUTPUT/Selah.app"
ditto "$APP" "$OUTPUT/Selah.app"
rm -f "$OUTPUT/Selah-macOS.zip"
ditto -c -k --sequesterRsrc --keepParent "$OUTPUT/Selah.app" "$OUTPUT/Selah-macOS.zip"
echo "Built $OUTPUT/Selah.app"
