#!/bin/bash

# Social Hub - Release Build Script
# This script builds, signs, notarizes, and packages the app

set -e

PROJECT_DIR="/Users/masdawg/Desktop/Brain/Mason/1. Projects/1. Code/1. Apps/fsocial/fsocial"
APP_NAME="fsocial"
DMG_NAME="SocialHub"
DEVELOPER_ID="Developer ID Application: Mason Earl (3FXGJUET7Y)"
NOTARY_PROFILE="fsocial-notary"

cd "$PROJECT_DIR"

echo "[1/6] Building release..."
xcodebuild -project "$APP_NAME.xcodeproj" -scheme "$APP_NAME" -configuration Release clean build 2>&1 | grep -E "(BUILD|error:|warning:)" || true

APP_PATH="/Users/masdawg/Library/Developer/Xcode/DerivedData/fsocial-axyvdsothnptwbhfditbzvrlwnsd/Build/Products/Release/$APP_NAME.app"

echo ""
echo "[2/6] Signing with Developer ID..."
codesign --force --deep --options runtime --sign "$DEVELOPER_ID" "$APP_PATH"

echo ""
echo "[3/6] Creating zip for notarization..."
ZIP_PATH="/tmp/$APP_NAME-notarize.zip"
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo ""
echo "[4/6] Submitting for notarization (this may take a minute)..."
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo ""
echo "[5/6] Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

echo ""
echo "[6/6] Creating DMG..."
DMG_DIR="$PROJECT_DIR/dist"
DMG_PATH="$DMG_DIR/$DMG_NAME.dmg"
mkdir -p "$DMG_DIR"
rm -f "$DMG_PATH"

TEMP_DMG_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"
ln -s /Applications "$TEMP_DMG_DIR/Applications"
hdiutil create -volname "Social Hub" -srcfolder "$TEMP_DMG_DIR" -ov -format UDZO "$DMG_PATH"
rm -rf "$TEMP_DMG_DIR"
rm -f "$ZIP_PATH"

echo ""
echo "============================================"
echo "BUILD COMPLETE"
echo "============================================"
echo ""
echo "Verifying signature..."
spctl --assess --type execute -v "$APP_PATH"
echo ""
echo "DMG ready at: $DMG_PATH"
ls -lh "$DMG_PATH"
echo ""
echo "Upload this file to your website."
