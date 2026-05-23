#!/usr/bin/env bash
set -euo pipefail

# Build, sign, notarize, and package WokyisScreensaver as a distributable DMG.
# Requires:
#   - xcodegen on PATH
#   - "Developer ID Application: Artyom Ivanov (453ZXYW34S)" in Keychain
#   - notarytool credentials stored under profile name $NOTARY_PROFILE

readonly SCHEME="WokyisScreensaver"
readonly VOLUME_NAME="Wokyis Screensaver"
readonly SIGN_IDENTITY="Developer ID Application: Artyom Ivanov (453ZXYW34S)"
readonly NOTARY_PROFILE="${NOTARY_PROFILE:-notarytool-profile}"

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DIST="$REPO_ROOT/dist"
readonly BUILD="$DIST/build"
readonly APP="$BUILD/Build/Products/Release/$SCHEME.app"
readonly ZIP="$DIST/$SCHEME.zip"
readonly STAGING="$DIST/dmg-staging"
readonly DMG="$DIST/$SCHEME.dmg"

step() { printf "\n\033[1;34m▶ %s\033[0m\n" "$*"; }

cd "$REPO_ROOT"

step "Generating Xcode project"
xcodegen generate >/dev/null

step "Building Release configuration (clean)"
xcodebuild -project "$SCHEME.xcodeproj" -scheme "$SCHEME" \
    -configuration Release -derivedDataPath "$BUILD" \
    clean build -quiet

step "Verifying app signature"
codesign -dvv "$APP" 2>&1 | grep -E "Authority|Timestamp|Runtime"

step "Zipping app for notarization"
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"

step "Submitting app to Apple notary (this can take a few minutes)"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

step "Stapling notarization ticket to app"
xcrun stapler staple "$APP"
spctl -a -vvv "$APP"

step "Building DMG staging directory"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

step "Creating DMG"
rm -f "$DMG"
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$STAGING" \
    -ov -format UDZO "$DMG" >/dev/null

step "Signing DMG"
codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG"

step "Submitting DMG to Apple notary"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait

step "Stapling DMG"
xcrun stapler staple "$DMG"
spctl -a -t open --context context:primary-signature -vvv "$DMG"

step "Cleaning up staging"
rm -rf "$STAGING" "$ZIP"

printf "\n\033[1;32m✓ DMG ready: %s\033[0m\n" "$DMG"
ls -la "$DMG"
