#!/usr/bin/env bash
# Archive Metrica for App Store Connect upload.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SCHEME="${SCHEME:-Metrica}"
ARCHIVE_PATH="${ARCHIVE_PATH:-$ROOT/build/Metrica.xcarchive}"
EXPORT_PATH="${EXPORT_PATH:-$ROOT/build/export}"
TEAM_ID="${DEVELOPMENT_TEAM:-}"

if [[ -z "$TEAM_ID" ]]; then
  echo "Вкажи Apple Team ID: export DEVELOPMENT_TEAM=XXXXXXXXXX"
  exit 1
fi

xcodegen generate

xcodebuild \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE_PATH" \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  archive

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$ROOT/ExportOptions.plist"

echo "IPA: $EXPORT_PATH/Metrica.ipa"
echo "Далі: Transporter або xcrun altool --upload-app …"
