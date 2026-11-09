#!/bin/zsh
# Builds a Release Translate.app, wraps it in a .dmg and writes SHA256SUMS.txt into dist/.
#
#   SIGNING_IDENTITY  codesign identity (default "-": ad-hoc; use "Developer ID Application: …")
#   NOTARY_PROFILE    notarytool keychain profile; when set, the .dmg is notarized and stapled
set -euo pipefail

readonly root=${0:A:h:h}
readonly identity=${SIGNING_IDENTITY:--}
readonly dist=$root/dist
readonly derived=$dist/DerivedData
readonly staging=$dist/staging

rm -rf "$dist"
mkdir -p "$dist"

# Automatic signing only knows ad-hoc here (no team in the project), so a Developer ID
# identity is applied manually with the team parsed from its "(TEAMID)" suffix. The build
# action, unlike archive, omits the secure timestamp and injects get-task-allow; notarization
# rejects both, so they are set explicitly.
signing=(CODE_SIGN_IDENTITY="$identity")
if [[ $identity =~ '\(([A-Z0-9]+)\)$' ]]; then
    signing+=(CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="$match[1]"
              OTHER_CODE_SIGN_FLAGS=--timestamp CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO)
fi

xcodebuild -project "$root/Translate.xcodeproj" -scheme Translate -configuration Release \
    -derivedDataPath "$derived" "${signing[@]}" -quiet build

readonly app=$derived/Build/Products/Release/Translate.app
readonly version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$app/Contents/Info.plist")
readonly dmg=$dist/Translate-$version.dmg

codesign --verify --deep --strict "$app"
mkdir -p "$staging"
cp -R "$app" "$staging/"
ln -s /Applications "$staging/Applications"
hdiutil create -volname Translate -srcfolder "$staging" -ov -format UDZO -quiet "$dmg"
rm -rf "$staging"

if [[ $identity != "-" ]]; then
    codesign --sign "$identity" --timestamp "$dmg"
fi
if [[ -n ${NOTARY_PROFILE:-} ]]; then
    xcrun notarytool submit "$dmg" --keychain-profile "$NOTARY_PROFILE" --wait
    xcrun stapler staple "$dmg"
fi

(cd "$dist" && shasum -a 256 "$(basename "$dmg")" > SHA256SUMS.txt)
rm -rf "$derived"
echo "built $dmg"
cat "$dist/SHA256SUMS.txt"
