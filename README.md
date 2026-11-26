# AutoDrop Keyboard (iOS 15.0+)

Native iOS Custom Keyboard (`UIInputViewController`) and pure UIKit Host App featuring a dark `#151515` / `#FF599E` theme, inline Settings & Live Resizer panel inside the keyboard, and a smart Auto-Drop engine (`OFF`, `ABC`, `123` Fast Numpad, `WORD`).

## Project Structure

- `project.yml`: XcodeGen specification generating `AutoDropKeyboard.xcodeproj` (zero entitlements for clean KSign/ESign sideloading)
- `Shared/AutoDropSettings.swift`: Settings model and `UserDefaults.standard` persistence
- `AutoDropHost/`: Pure UIKit Host App (`AppDelegate` + `MainViewController`, `com.autodrop.keyboard`) with Setup Guide and Live Tester
- `AutoDropKeyboardExt/`: UIKit Keyboard Extension (`com.autodrop.keyboard.ext`, `com.apple.keyboard-service`) with all Auto-Drop, delay, trigger, height, font, gap, and haptics controls built directly into the toolbar Gear overlay
- `.github/workflows/build-ipa.yml`: GitHub Actions macOS workflow building an unsigned `AutoDropKeyboard.ipa`

## Building Locally (macOS)

```bash
brew install xcodegen
xcodegen generate
open AutoDropKeyboard.xcodeproj
```

To build an unsigned `.ipa` locally:

```bash
xcodebuild -project AutoDropKeyboard.xcodeproj \
  -scheme AutoDropHost \
  -configuration Release \
  -sdk iphoneos \
  -archivePath build/AutoDropHost.xcarchive \
  archive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""

mkdir -p Payload
cp -R build/AutoDropHost.xcarchive/Products/Applications/AutoDropHost.app Payload/
zip -qry AutoDropKeyboard.ipa Payload
```
