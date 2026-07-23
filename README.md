# Selah

Selah is a private, offline macOS menu-bar utility that offers one Bible verse each day. It is written in SwiftUI and contains no analytics, accounts, advertising, or network requests.

- [Privacy policy](https://kolt6465.github.io/selah/privacy.html)
- [Support](https://kolt6465.github.io/selah/support.html)

## Install

1. Unzip `Selah-macOS.zip`.
2. Move `Selah.app` to Applications.
3. Open Selah. Its book-and-sun icon appears in the menu bar rather than the Dock.

Because this local build is ad-hoc signed rather than notarized, macOS may ask you to confirm the first launch. If it blocks the app, Control-click Selah, choose **Open**, then confirm **Open**.

## Build and test

Requires Xcode 16 or later and macOS 13 or later.

```sh
xcodebuild -project Selah.xcodeproj -scheme Selah -destination 'platform=macOS' test -only-testing:SelahTests
./scripts/build_release.sh
```

The `SelahUITests` target contains the launch smoke test. Running it requires macOS Accessibility/Automation permission for Xcode or the invoking test runner.

To refresh the bundled Scripture data, download the WEB Protestant HTML archive from eBible.org, extract it, and run:

```sh
python3 scripts/import_web.py /path/to/extracted-html Selah/Resources/bible_web.json
```

## Scripture

Selah uses the World English Bible, Protestant Edition (66 books, U.S. spelling), from <https://ebible.org/engwebp/>. The Scripture text is in the public domain. “World English Bible” is a trademark of eBible.org; Selah does not modify the verse text and is not affiliated with eBible.org.
