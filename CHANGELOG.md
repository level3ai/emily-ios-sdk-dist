# Changelog

All notable changes to the EmilyChat iOS SDK. This project follows
[Semantic Versioning](https://semver.org/).

## [1.2.2] - Unreleased

The WebView now always loads the sid-routed CDN container
(`https://sdk.lv3.ai/native/mobile.html?sid=<serviceSid>`): the serviceSid
alone decides the environment *and* any server-side version pin, so there is
no environment to select client-side anymore.

### Breaking

- `EmilyChatEnvironment` is removed.
- `EmilyChatOptions.environment` is replaced by an optional
  `containerURL: URL?` — `nil` (default) means the sid-routed CDN; a custom
  URL (local dev / on-prem) is loaded verbatim, with no sid appended.

### Fixed

- Keyboard: the WebView now resizes to the keyboard's top edge instead of
  letting WebKit scroll the document (which left a white band between the chat
  input and the keyboard). The default form accessory bar (↑ ↓ ✓) is removed,
  and dragging down on the message list dismisses the keyboard interactively.

## [1.2.1] - 2026-08-04

Maintenance release. **No source or API changes from 1.2.0** — the SDK is
rebuilt and re-published to exercise the release pipeline end to end. Upgrading
is optional; 1.2.0 remains available and functionally identical.

## [1.2.0] - 2026-07-31

First public release. The SDK now ships as a pre-built XCFramework resolved
through Swift Package Manager; earlier versions were never published outside
Level3AI.

### Added

- Privacy manifest (`PrivacyInfo.xcprivacy`) bundled in the framework: no
  tracking, no collected data types, no required-reason API usage.

### Changed

- **Breaking:** the entry-point singleton is now `Emily.shared`, previously
  `EmilyChat.shared`. The module name is unchanged, so `import EmilyChat` still
  applies — only the type is renamed. A type whose name matches its module name
  cannot be expressed in the generated `.swiftinterface`, which binary
  distribution requires.
- **Breaking:** `EmilyChatStyle` and `EmilyChatOptions.style` were removed.
  Brand color, theme, header title, bubble colors and logos now come from the
  tenant's server-side chat configuration. Drop the argument; move the values
  to the Level3AI admin console.
- **Breaking:** user attributes are now merged flat into the conversation,
  matching the web SDK's `Emily.setAttributes({ … })`. Previously they were
  nested one level deeper under an `attributes` key, so app-side identity did
  not line up with what browser integrations produced. `setAttributes(_:)` and
  `EmilyChatOptions.attributes` keep the same Swift signature — only the wire
  format changed. Attribute keys colliding with the SDK's own init options are
  dropped and reported as `.bridgeError(stage: "init.attributes", …)`.
- The SDK now ships as a pre-built XCFramework rather than source. Its public
  enums are therefore non-frozen: add `@unknown default` when switching over
  `EmilyChatEvent` (a warning today, an error under the Swift 6 language mode).
