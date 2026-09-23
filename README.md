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
.package(url: "https://github.com/level3ai/emily-ios-sdk-dist.git", from: "3.0.0")
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

Configure at launch, hand over the user when you have one, open when they ask.

```swift
import EmilyChat

// 1. At launch — AppDelegate, SceneDelegate or your App's init.
Emily.shared.configure(EmilyChatOptions(serviceSid: "LV3-YOUR-SERVICE-SID"))

// 2. Whenever you know who the user is.
Emily.shared.setUserToken(session.token)

// 3. When they tap Support.
Emily.shared.open(from: self)
```

In a real app:

```swift
import UIKit
import EmilyChat

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Emily.shared.configure(
            EmilyChatOptions(
                serviceSid: "LV3-YOUR-SERVICE-SID",
                locale: Locale.current.identifier
            )
        )
        return true
    }
}

final class SupportButton: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // The user is known here, not at launch. Setting it now is fine:
        // it reaches the chat on the next open.
        Emily.shared
            .setUserToken(Session.current?.token)
            .setMetadata(["plan": "pro", "tenantId": 42])
    }

    @IBAction func openChat() {
        Emily.shared.open(from: self)
    }
}
```

Every setter returns `Emily` and is `@discardableResult`, so chain them or
call them one by one, whichever reads better.

Diagnostics go to the system log
(`log stream --predicate 'subsystem == "ai.level3.emily.chat"' --level debug`).

---

## Common tasks

### Identify the user

```swift
Emily.shared.setUserToken(session.token)
```

The signed token your backend issues; Emily verifies it and trusts that
identity for the conversation. Pass `nil` to go back to an anonymous chat.

Takes effect on the next `open(from:)`. A chat already on screen keeps the
identity it booted with.

### Attach context to the conversation

```swift
Emily.shared.setMetadata(["plan": "pro", "tenantId": 42])
```

Context that describes the conversation rather than the person (`plan`,
`tenantId`, `pageUrl`, …). It **replaces** rather than merges, so pass the
whole dictionary each time; `nil` clears it.

**Set it before `open(from:)`, and only a new conversation picks it up.**
Metadata is attached at the moment a conversation is created, which has two
consequences worth knowing:

- Calling it while the chat is on screen does nothing to that chat.
- If the user still has a conversation in progress, opening resumes it and the
  metadata is ignored. It applies to the next conversation actually created.

For anything that has to reach a live chat, or update a conversation already
under way, use `setAttributes(_:)` below.

Values must be JSON-serializable via `JSONSerialization` — the same rule
applies to `setAttributes(_:)`. Anything else is logged and skipped instead of
crashing.

### Set user attributes

```swift
Emily.shared.setAttributes([
    "userId": user.id,
    "contact_id": user.crmContactId
])
```

Who the user is: name, email, plan, your own CRM ids. Unlike `setMetadata(_:)`
it **merges**, so you can add fields as you learn them.

Call it at any point — the values reach the chat if one is already on screen,
and are kept for the next one.

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
Emily.shared.logout()      // clears the token, metadata and attributes, locally and in the live chat
Emily.shared.close()       // (optional) close the chat surface
```

Works with or without the chat on screen — either way the backend session
ends and the push registration is cleaned up. The next chat starts anonymous
until you hand over a new token.

### Attachments and voice input

Taking a photo or recording a voice message inside the chat needs the matching
iOS permission, and the usage description for it has to come from your app's
`Info.plist` — the SDK does not add it for you. Declare the keys your Channel's
inputs need:

```xml
<!-- Image or video upload enabled on your Channel -->
<key>NSCameraUsageDescription</key>
<string>Lets you take a photo to attach to your conversation.</string>

<!-- Voice input or video upload enabled on your Channel -->
<key>NSMicrophoneUsageDescription</key>
<string>Used to record voice messages in support chat.</string>
```

Without the camera key, iOS terminates the app the moment a user taps
**Take Photo** (or **Take Photo or Video**) in the attachment picker; the same
happens to a video recording without the microphone key. Without the
microphone key the chat's microphone button does not appear at all. Picking an
existing photo or file needs no key.

### Push notifications

Your app owns APNs registration — the permission prompt,
`registerForRemoteNotifications()`, and the `UNUserNotificationCenterDelegate`
— the SDK never asks for permission itself. Wire Emily in at three points:

```swift
// 1. Relay the device token (AppDelegate).
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    #if DEBUG
    Emily.shared.setPushToken(deviceToken, environment: .sandbox)
    #else
    Emily.shared.setPushToken(deviceToken, environment: .production)
    #endif
}

// 2. Open the chat when the user taps an Emily notification.
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            didReceive response: UNNotificationResponse,
                            withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    if Emily.shared.handleNotificationTap(userInfo, from: rootViewController) {
        completionHandler()
        return
    }
    // ... your own notification routing ...
    completionHandler()
}

// 3. (Optional) No system banner for the chat reply the user is already reading.
func userNotificationCenter(_ center: UNUserNotificationCenter,
                            willPresent notification: UNNotification,
                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    if Emily.isEmilyNotification(notification.request.content.userInfo),
       Emily.shared.isChatOpen {
        completionHandler([])
        return
    }
    completionHandler([.banner, .list, .sound])
}
```

Opening the chat also clears Emily's already-delivered notifications from
Notification Center automatically — a user who reaches the chat on their own
isn't left with stale "new message" alerts. Nothing to wire up.

`setPushToken` works before `configure(_:)`, keeps the token in memory only
(the SDK persists nothing), and the token survives `logout()` — it identifies
the device, not the user. Use `.sandbox` for Xcode-installed builds and
`.production` for TestFlight / App Store: APNs tokens are only deliverable
through the environment that issued them. `Emily.isEmilyNotification(_:)` is
static and thread-safe, so it fits anywhere in your notification plumbing.

### Localization

Set `locale` on `EmilyChatOptions` to a BCP-47 tag (`"en"`, `"zh-Hans"`, …).
Leave it `nil` and the chat picks a language itself.

To change it later, call `configure(_:)` again with the new value — when the
user actually switches language, not routinely before every open.

---

## API reference

### `Emily` (singleton, `@MainActor`)

| Member | Purpose |
| --- | --- |
| `configure(_:)` -> `Emily` | Stores the configuration. Call it once, at launch. `@discardableResult`. |
| `open(from:animated:completion:)` | Opens the chat, always full screen. |
| `setUserToken(_:)` -> `Emily` | Sets the end-user token used from the next `open(from:)`; `nil` = anonymous. `@discardableResult`. |
| `setMetadata(_:)` -> `Emily` | Replaces the context attached to the next conversation **created**; set it before `open(from:)`, and note a resumed conversation ignores it. `nil` clears it. `@discardableResult`. |
| `setAttributes(_:)` -> `Emily` | Merges user attributes into the conversation, reaching a chat already on screen. `@discardableResult`. |
| `close(animated:completion:)` | Closes the chat. |
| `logout()` | Clears the user token, metadata and attributes, and ends the backend session. Works whether or not the chat is on screen. |
| `setPushToken(_:environment:)` -> `Emily` | Relays the APNs device token (`Data` or hex `String`). `@discardableResult`. |
| `handleNotificationTap(_:from:animated:completion:)` -> `Bool` | Opens the chat for a tapped Emily notification; `false` = not Emily's (or not configured), route it yourself. |
| `isChatOpen` | Whether the chat modal is currently on screen. |
| `isEmilyNotification(_:)` (static) | Whether a notification payload belongs to Emily. Any thread. |

All calls are main-actor isolated, which is where UIKit code already runs.
Every setter also works before `configure(_:)`, so you can hand over a token,
metadata, attributes or a push token in whatever order suits your app.

### `EmilyChatOptions`

| Field | Type | Purpose |
| --- | --- | --- |
| `serviceSid` | `String` (required) | Your service identifier. |
| `locale` | `String?` | BCP-47 language tag. `nil` = auto-detect. |
| `host` | `String?` | Base URL of your self-hosted Emily gateway (e.g. `"https://example.lv3.ai/"`), for private (on-premises) deployments. `nil` = Level3AI's standard cloud gateway. |

The user token, conversation metadata and user attributes describe the person
rather than the app, so they have their own setters: `setUserToken(_:)`,
`setMetadata(_:)` and `setAttributes(_:)`.

---

## License

MIT — see [`LICENSE`](LICENSE).
