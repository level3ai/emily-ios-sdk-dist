# Changelog

All notable changes to the EmilyChat iOS SDK. This project follows
[Semantic Versioning](https://semver.org/).

## [2.1.0] - 2026-08-26

Push-notification support. The host app owns APNs registration — the
permission prompt, `registerForRemoteNotifications()`, and the
notification-center delegate — the SDK never asks for permission itself. It
relays the device token to the Emily service and routes the taps that belong
to it into the chat.

### Added

- `Emily.shared.setPushToken(_:environment:)` — hand over the APNs device
  token, as the raw `Data` from the AppDelegate callback or an
  already-hex-encoded `String`. Legal before `configure(_:)`; the token is
  held in memory only (the SDK persists nothing — its privacy manifest stays
  empty), survives `logout()` (it identifies the device, not the user), and
  is forwarded to the chat whenever one boots.
- `EmilyPushEnvironment` — `.production` (the default) / `.sandbox`, so the
  backend pushes through the APNs environment that issued the token:
  `.sandbox` for Xcode-installed builds, `.production` for TestFlight /
  App Store.
- `Emily.isEmilyNotification(_:)` — whether a notification payload belongs to
  Emily. Static, callable from any thread and before `configure(_:)`.
- `Emily.shared.handleNotificationTap(_:from:animated:completion:)` — opens
  the chat for a tapped Emily notification. Returns `false` (so your own
  routing takes over) for non-Emily payloads or when `configure(_:)` hasn't
  run.
- `Emily.shared.isChatOpen` — whether the chat modal is on screen; use it in
  `willPresent` to suppress the system banner for the chat reply the user is
  already reading.
- Opening the chat (including returning to it from the background) clears
  Emily's already-delivered notifications from Notification Center, so a user
  who reaches the chat on their own isn't left with stale "new message"
  alerts. Automatic — nothing for the host app to wire up.

### Changed

- `logout()` now flushes the logout through the Emily web layer even when the
  chat is **not** on screen, by briefly booting the chat container in an
  off-screen WebView — so the backend session ends and the push token is
  unregistered no matter when you call it. No API change; with the chat open
  the behavior is as before.

## [2.0.0] - 2026-08-17

Company-wide namespace rebrand from `ai.lv3` to `ai.level3`. The Swift API,
module name (`EmilyChat`), and SPM/CocoaPods artifact names are unchanged —
on iOS the only behavioral change is the diagnostics log identifier. The major
version aligns with the Android SDK's new Maven coordinate
(`ai.level3.emily:emily-chat:2.0.0`), where the rename is source-breaking.

### Breaking

- The system-log subsystem is now `ai.level3.emily.chat` (was
  `ai.lv3.emily.chat`). Update any saved Console.app filters or scripts:
  `log stream --predicate 'subsystem == "ai.level3.emily.chat"' --level debug`.

## [1.2.3] - 2026-08-13

This release narrows the public API to what a host app actually drives: one
singleton, the options it hands in, and the events it gets back.

### Added

- `EmilyChatOptions.host` — base URL of your self-hosted Emily gateway, for
  private (on-premises) deployments. `nil` (the default) keeps Level3AI's
  standard cloud gateway.

### Breaking

- `present(from:animated:completion:)` and `dismiss(animated:completion:)` are
  removed; `open(from:animated:completion:)` and `close(animated:completion:)`
  — previously aliases — are now the only names, matching the browser JS API
  and the Android / Flutter / React Native packages. Rename call sites 1:1;
  parameters and behaviour are unchanged.
- `Emily.shared.onEvent` and the `EmilyChatEvent` type are removed. The SDK now
  handles everything they were for:
  - **Closing.** The chat dismisses itself when the user taps its close
    control, so the `.closeRequest` handler you had is no longer needed —
    delete it. `Emily.shared.close()` still closes it programmatically.
  - **Load failures.** If the chat can't load — or the page loads but never
    becomes ready within 15 seconds — the SDK shows a built-in
    "Chat unavailable" page with retry and close buttons instead of leaving the
    user on a blank full-screen modal.
  - **Diagnostics.** Everything else (a `metadata` value that isn't
    JSON-serializable, an attribute using a reserved name, `configure(_:)` not
    called before presenting, the load failure itself) goes to the system log
    under the `ai.lv3.emily.chat` subsystem. Read it in Console.app or with
    `log stream --predicate 'subsystem == "ai.lv3.emily.chat"' --level debug`.
- `EmilyChatOptions.attributes` is removed, along with the `attributes:`
  argument on `EmilyChatOptions.init`. `Emily.shared.setAttributes(_:)` is now
  the only entry point for user attributes: identity data changes during a
  session, while the configuration is handed in once. Move the dictionary from
  your `EmilyChatOptions(…)` call to a `setAttributes(_:)` call — anything set
  before the first present still reaches the chat at boot. As a side effect,
  `setAttributes(_:)` now also works before `configure(_:)`, where it used to be
  dropped.
- `EmilyChatViewController` is now internal — the chat is reached only through
  `Emily.shared.open(from:)`, which owns the presentation. The class, its
  initializer, its properties and its delegate methods are no longer public,
  and presenting the chat inside your own navigation stack is no longer
  supported.
- `Emily.shared.presentedController` is no longer public for the same reason.
- `Emily.shared.options` is now internal. Your app is the source of that
  configuration, and keeping it private means a configured `userToken` is not
  readable by other code linked into the app.
- `EmilyChatEvent.ready(sdkVersion:)` becomes `EmilyChatEvent.ready`. The
  chat's own version is managed by Level3AI and is not something to branch on;
  `switch` statements binding the associated value need updating.
- `Emily.PresentationStyle` is removed, along with the `style:` argument on
  the open call. The chat is always a full-screen modal (slide-up, no
  swipe-to-dismiss); the `.sheet` and `.pageSheet` presentations are gone.
  Drop the argument — `Emily.shared.open(from: self)` is unchanged.
- `EmilyChatOptions.containerURL` is removed, along with the `containerURL:`
  argument on `EmilyChatOptions.init`. Your `serviceSid` already selects the
  right service and configuration, so there is no address to point the SDK at.
  Delete the argument from your `EmilyChatOptions(…)` call.

## [1.2.2] - 2026-08-06

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
