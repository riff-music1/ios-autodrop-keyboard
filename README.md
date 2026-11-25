# AutoDrop Keyboard (iOS 15.0+)

Native iOS Custom Keyboard (`UIInputViewController`) and SwiftUI Host App featuring a dark `#151515` / `#FF599E` theme, live inline height/font/gap resizer, and a smart Auto-Drop engine (`OFF`, `ABC`, `123` Fast Numpad, `WORD`).

## Project Structure

- `project.yml`: XcodeGen specification generating `AutoDropKeyboard.xcodeproj`
- `Shared/AutoDropSettings.swift`: Shared App Group (`group.com.autodrop.keyboard`) defaults and cross-process Darwin notification sync
- `AutoDropHost/`: SwiftUI Host App (`com.autodrop.keyboard`) with Setup Guide, Live Tester, Auto-Drop Settings, and Haptics toggle
- `AutoDropKeyboardExt/`: UIKit Keyboard Extension (`com.autodrop.keyboard.ext`, `com.apple.keyboard-service`)
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
