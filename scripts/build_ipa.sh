#!/bin/bash
# Tăng build number trong pubspec.yaml rồi build IPA cho TestFlight.
# Dùng: ./scripts/build_ipa.sh
set -e

cd "$(dirname "$0")/.."

CURRENT=$(grep '^version:' pubspec.yaml | sed -E 's/version: ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)/\1+\2/')
VERSION_NAME=$(echo "$CURRENT" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT" | cut -d'+' -f2)
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))

sed -i '' "s/^version: .*/version: ${VERSION_NAME}+${NEW_BUILD_NUMBER}/" pubspec.yaml

echo "Version: ${VERSION_NAME}+${BUILD_NUMBER} -> ${VERSION_NAME}+${NEW_BUILD_NUMBER}"

flutter build ipa

echo ""
echo "IPA sẵn sàng tại: build/ios/ipa/"
ls build/ios/ipa/*.ipa
