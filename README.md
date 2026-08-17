# EmilyChat — iOS SDK

Embeddable customer-support chat for iOS: present the chat from anywhere in
your app and tell it who the signed-in user is.

The chat itself — theme, colors, header, message bubbles, copy — is served by
Level3AI and configured per service, so it changes without an App Store
release.

---

## Requirements

| | |
| --- | --- |
| iOS | 14.0+ |
| Xcode | 26.0.1+ (the SDK ships as a pre-built binary; older Xcode can't read its module interface) |
| Network | HTTPS access to `*.lv3.ai` |

You also need a **service SID** from your Level3AI
contact, and your app's bundle id has to be allow-listed on that service before
the chat can connect.

---

## Installation

### Swift Package Manager

In Xcode → `File ▸ Add Package Dependencies…`:

```
https://github.com/level3ai/emily-ios-sdk-dist
```

or in `Package.swift`:

```swift
.package(url: "https://github.com/level3ai/emily-ios-sdk-dist.git", from: "1.2.3")
```

then add `"EmilyChat"` to your target's dependencies.

### CocoaPods

The pod is served from our own spec repo rather than the public CocoaPods
trunk, which stops accepting new versions on 2 December 2026. Add the source
line once, alongside whatever sources you already use:

```ruby
source 'https://cdn.cocoapods.org/'
source 'https://github.com/level3ai/emily-ios-sdk-dist.git'

target 'YourApp' do
  pod 'EmilyChat'
end
```

Both package managers install the identical binary.

> **Pick one, never both.** Integrating through SPM *and* CocoaPods in the same
> app embeds two copies of the framework, which surfaces as duplicate symbols
> at link time or `Class EmilyChat… is implemented in both …` at runtime.

---

## Quick start

```swift
import EmilyChat

Emily.shared
    .configure(EmilyChatOptions(serviceSid: "LV3-YOUR-SERVICE-SID"))
    .open(from: self)
```

A fuller setup that identifies the user:

```swift
import UIKit
import EmilyChat

final class SupportButton: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Configure once — in AppDelegate, or any time before the first open.
        Emily.shared.configure(
            EmilyChatOptions(
                serviceSid: "LV3-YOUR-SERVICE-SID",
                userToken: Session.current?.token,
                locale: Locale.current.identifier,
                metadata: ["plan": "pro", "tenantId": 42]
            )
        )
    }

    @IBAction func openChat() {
        Emily.shared.open(from: self)
    }
}
```

Diagnostics go to the system log
(`log stream --predicate 'subsystem == "ai.level3.emily.chat"' --level debug`).

`configure(_:)` is `@discardableResult`, so calling it without chaining is
fine.

---

## Common tasks

### Set user attributes

```swift
Emily.shared.setAttributes([
    "userId": user.id,
    "contact_id": user.crmContactId
])
```

`setAttributes(_:)` merges user attributes (name, email, custom fields…) into
the conversation. Call it at any point — the values reach the live chat if one
is open, and are kept for the next one.

### Attach context to every message

`metadata` travels with the conversation (`plan`, `tenantId`, `pageUrl`, …) and
takes `[String: Any]` where every value must be JSON-serializable via
`JSONSerialization` — the same rule applies to what you hand
`setAttributes(_:)`. Anything else is logged and skipped instead of crashing.

### Presentation

```swift
Emily.shared.open(from: self)
```

The chat is always a full-screen modal: slide-up animation, covers the whole
screen, **not dismissable by gesture**. It draws its own header and close
control, so there is no navigation chrome to configure around it.

The chat's own close control dismisses it — the SDK handles that itself, so
there is nothing to implement. `Emily.shared.close()` is there for closing it
programmatically.

### Log out

```swift
Emily.shared.logout()      // clears userToken + attributes, locally and in the live chat
Emily.shared.close()       // (optional) close the chat surface
```

### Localization

Pass a BCP-47 tag as `locale` (`"en"`, `"zh-Hans"`, …). Leave it `nil` and the
chat picks a language itself.

---

## API reference

### `Emily` (singleton, `@MainActor`)

| Member | Purpose |
| --- | --- |
| `configure(_:)` -> `Emily` | Stores the options used by the next `open(from:)`. Returns `self` for chaining; `@discardableResult`. |
| `open(from:animated:completion:)` | Opens the chat, always full screen. |
| `close(animated:completion:)` | Closes the chat. |
| `setAttributes(_:)` | Sets user attributes on the conversation. |
| `logout()` | Clears the user identity locally and in the live chat. |

All calls are main-actor isolated, which is where UIKit code already runs.

### `EmilyChatOptions`

| Field | Type | Purpose |
| --- | --- | --- |
| `serviceSid` | `String` (required) | Your service identifier. |
| `userToken` | `String?` | Identifies / authenticates the conversation owner. Omit for anonymous chats. |
| `locale` | `String?` | BCP-47 language tag. `nil` = auto-detect. |
| `metadata` | `[String: Any]?` | Free-form context sent with the conversation. JSON-safe values only. |
| `host` | `String?` | Base URL of your self-hosted Emily gateway (e.g. `"https://example.lv3.ai/"`), for private (on-premises) deployments. `nil` = Level3AI's standard cloud gateway. |

---

## License

MIT — see [`LICENSE`](LICENSE).
