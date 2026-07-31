# EmilyChat — iOS SDK

Embeddable customer-support chat for iOS, powered by a `WKWebView` that hosts
the Emily web bundle from the Level3 CDN.

* **Minimum iOS:** 14.0
* **Distribution:** Swift Package Manager (pre-built XCFramework)
* **Surface area:** one singleton (`Emily.shared`) + one `UIViewController` (`EmilyChatViewController`)

The native layer owns lifecycle, a small JSON bridge, and a typed Swift API.
All UI — themes, message bubbles, file picker, voice notes — ships from the web
bundle, so visual changes go live without a new App Store build.

---

## Installation

In Xcode → `File ▸ Add Package Dependencies…`:

```
https://github.com/level3ai/emily-ios-sdk-dist
```

or in `Package.swift`:

```swift
.package(url: "https://github.com/level3ai/emily-ios-sdk-dist.git", from: "1.2.0")
```

then add `"EmilyChat"` to your target's dependencies.

You need a **service SID** (`LV3-` + 32 hex chars) from your Level3AI contact,
and your app's bundle id has to be allow-listed on that service before the chat
can connect.

---

## Quick start

```swift
import EmilyChat

Emily.shared
    .configure(EmilyChatOptions(serviceSid: "LV3-YOUR-SERVICE-SID"))
    .open(from: self)
```

A fuller setup that listens for events:

```swift
import UIKit
import EmilyChat

final class SupportButton: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // 1. Configure once (e.g. in AppDelegate or before the first present).
        Emily.shared.configure(
            EmilyChatOptions(
                serviceSid: "LV3-YOUR-SERVICE-SID",
                userToken: Session.current?.token,
                locale: Locale.current.identifier,
                metadata: ["plan": "pro", "tenantId": 42]
            )
        )

        // 2. React to events from the chat.
        Emily.shared.onEvent = { [weak self] event in
            switch event {
            case .ready(let version):
                print("Emily widget ready, v\(version ?? "?")")
            case .closeRequest:
                Emily.shared.close()
            case .bridgeError(let stage, let message):
                print("Emily bridge error [\(stage)]: \(message)")
            case .loadFailed(let error):
                self?.showOfflineAlert(error: error)
            @unknown default:
                break
            }
        }
    }

    @IBAction func openChat() {
        Emily.shared.open(from: self)
    }
}
```

> **`@unknown default` is required.** The SDK ships as a binary framework built
> with library evolution, so its enums are non-frozen and may gain cases in a
> minor release. Omitting it warns today and is a hard error under the Swift 6
> language mode.

`open(from:)` / `close()` are aliases for `present(from:)` / `dismiss()` — use
whichever pair reads better. `configure(_:)` is `@discardableResult`, so calling
it without chaining is fine.

### Presentation styles

```swift
// (default) Full-screen modal: slide-up, covers everything, no swipe-to-dismiss.
Emily.shared.present(from: self)

// iOS-native sheet (iOS 15+): large detent, grabber, swipe-down dismisses.
Emily.shared.present(from: self, style: .sheet)

// Plain page sheet (no grabber).
Emily.shared.present(from: self, style: .pageSheet)
```

For `.sheet` / `.pageSheet`, a swipe-down dismissal emits the same
`.closeRequest` event as the chat's own close button, so you don't need to
special-case interactive vs. programmatic dismissal. `.fullScreen` can't be
dismissed by gesture — handle `.closeRequest` and call `Emily.shared.dismiss()`.

### Identifying the signed-in user

```swift
Emily.shared.setAttributes([
    "userId": user.id,
    "contact_id": user.crmContactId
])
```

Call it after login and after each token refresh. Attributes are merged **flat**
into the conversation, identically to the web SDK's
`Emily.setAttributes({ userId, contact_id })`, so an app and a browser
integration of the same tenant produce the same shape on the backend.

Avoid the names the SDK reserves for its own init options (`serviceSid`,
`userToken`, `locale`, `metadata`, `style`, `showLauncher`, `fullscreen`) — such
a key is dropped and reported as `.bridgeError(stage: "init.attributes", …)`.

### Logging out

```swift
Emily.shared.logout()      // clears userToken + attributes
Emily.shared.dismiss()     // (optional) close the chat surface
```

---

## API surface

### `Emily` (singleton)

| Member | Purpose |
| --- | --- |
| `configure(_:)` -> `Emily` | Stores the options used by the next `present(from:)` / `open(from:)`. Returns `self` for chaining; `@discardableResult`. |
| `present(from:style:animated:completion:)` | Modally presents the chat. Defaults to `.fullScreen`. Also supports `.sheet` and `.pageSheet`. |
| `open(from:style:animated:completion:)` | Alias for `present(from:)`. |
| `dismiss(animated:completion:)` | Dismisses the chat modal. Sends `CLOSE` first. |
| `close(animated:completion:)` | Alias for `dismiss(animated:completion:)`. |
| `setAttributes(_:)` | Merges attributes into the live conversation and persists them for the next present. |
| `logout()` | Clears the user identity locally and in the live chat. |
| `onEvent` | `((EmilyChatEvent) -> Void)?` — every event, always on the main thread. |
| `options` | The currently configured `EmilyChatOptions`. Read-only. |
| `presentedController` | The active `EmilyChatViewController`, if any. |

### `EmilyChatOptions`

`serviceSid` (required), `userToken`, `locale`, `metadata`, `attributes`, plus an
`environment` selector (`.production` / `.staging` / `.custom(url:)`).

`metadata` and `attributes` take `[String: Any]` where every value must be
JSON-serializable via `JSONSerialization`; anything else surfaces as
`.bridgeError(stage: "init", …)` instead of crashing.

### `EmilyChatEvent`

```swift
case ready(sdkVersion: String?)
case closeRequest
case bridgeError(stage: String, message: String)
case loadFailed(Error)
```

Non-frozen — always include `@unknown default` when switching over it.

### Appearance

There is no style or branding option in the API. Brand color, light/dark theme,
header title and alignment, bubble colors and logos all come from your chat
configuration on the Level3AI server, which the web bundle fetches at boot.
Ask your Level3AI contact to change them — no app release needed.

---

## Privacy

The framework bundles a `PrivacyInfo.xcprivacy` declaring no tracking, no
collected data types, and no required-reason API usage — accurate for the
binary, which is a `WKWebView` host plus a JSON bridge.

Your app still needs to declare in its own App Store privacy nutrition label
whatever your support conversations collect (messages, contact details,
attachments, …). That's a property of your Level3AI service, not of this SDK.

---

## License

MIT — see [`LICENSE`](LICENSE).
