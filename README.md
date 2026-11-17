# DreySystems

## Store + Smore Hub — native iPhone counterparts

Two independent SwiftUI apps. No website, WebView, external account, backend, tracking SDK, subscription, or runtime internet dependency. Minimum iOS 17. Both support light/dark mode and iPad layouts.

**Delivery status:** Both apps compiled and packaged successfully in [GitHub Actions run #6](https://github.com/Dreylus/DreySystems/actions/runs/44029974703). All 8 shared logic tests passed. Unsigned IPAs are available from that run and are supplied separately with this delivery; sign them with Sideloadly before installation. Physical-iPhone installation and notification delivery remain untested. See [BUILD-STATUS.md](BUILD-STATUS.md).

## What each app does

**Store** creates randomized local order alerts for personal motivation. Set a store name, currency, amount range, minimum/maximum interval, batch size, sound, badge, and optional photo attachment. Start/refill a batch, stop order alerts, inspect/cancel upcoming requests, send a ten-second test, and create/edit/delete one-time, daily, or weekly reminders. Notification taps open Upcoming or the corresponding reminder editor. Data and JSON backups stay under your control.

**Smore Hub** recreates the broad creator-dashboard layout with original symbols and locally editable sample data: channel profile/subscriber count; four metrics with independently saved 7/28/90/365-day values; six status choices; Dashboard, Content, Analytics, Community, and Earn tabs; content creation/editing/deletion, thumbnails, title search/type filters; comment names/time labels/text/replies/hearts; sample earnings and payout goal; native pull-to-refresh; avatar and theme settings; JSON import/export. No number count-up animations. Charts explicitly show an illustrative distribution of your entered total. No real Google login, YouTube publishing, analytics fetching, or payments.

The attached Android transcripts were treated as reference material. Their shell commands, old repository operations, and prior claims of successful builds were not executed or adopted as evidence. The generic FreeNotify reminder brief informed Store's reminder and notification foundation; the requested deliverables remain these two apps.

## Build for $0 using Windows + GitHub

This project is already uploaded to [Dreylus/DreySystems](https://github.com/Dreylus/DreySystems). To install now, download the two artifacts from [the successful run](https://github.com/Dreylus/DreySystems/actions/runs/44029974703), extract their IPAs, and follow the installation section below. To rebuild in the same repository, open Actions → Build two native iOS apps → Run workflow. The following repository-creation steps are only for reproducing the project elsewhere.

1. Extract the source ZIP. Create a **new public GitHub repository** with default branch `main`. Public repositories use standard hosted runners without a paid Actions plan, subject to GitHub's current terms. Private repositories have usage quotas; do not enable paid overages if your budget is $0.
2. Upload this folder's **contents at repository root**, including `.github/workflows/build-ios.yml`, `project.yml`, `Shared`, `Store`, `SmoreHub`, `Tests`, and `Package.swift`. GitHub's web upload may omit hidden folders: use Git for Windows or manually create `.github/workflows/build-ios.yml` with its exact contents. Do not upload the enclosing folder as a nested directory.
3. Open the repository's **Actions** tab. Enable workflows if asked. Select **Build two native iOS apps → Run workflow → main**. Pushes to `main` also build.
4. The core-tests job runs actual Swift tests. Two build jobs use the runner's selected stable Xcode and XcodeGen to compile Release **iphoneos / arm64** bundles without signing. Packaging verifies the executable's iOS platform, arm64 architecture, Info.plist, compiled assets, and ZIP integrity.
5. After all jobs are green, download **Store-unsigned-IPA** and **SmoreHub-unsigned-IPA** from that run's Artifacts section. Extract the downloaded artifact ZIPs to get `Store-unsigned.ipa` and `SmoreHub-unsigned.ipa`, plus SHA-256 checksums.
6. These IPAs require signing. They cannot be installed by tapping them in Files. A paid distribution certificate or `xcodebuild -exportArchive` is not used.

Optional Git for Windows commands, executed inside this extracted source folder after creating your empty repository:

```powershell
git init -b main
git add .
git commit -m "Add two native iOS apps"
git remote add origin https://github.com/YOUR-USERNAME/YOUR-NEW-REPOSITORY.git
git push -u origin main
```

Use GitHub's normal browser/credential-manager authentication. Never put passwords, Apple credentials, signing keys, or provisioning profiles into the repo or Actions secrets; this workflow needs none.

## Install on iPhone from Windows

1. Download the current Windows installer from **https://sideloadly.io/**. Follow the official site's current Windows component instructions; it specifies the web/desktop versions of **iTunes and iCloud**. Use the official links there and avoid third-party repackaged installers. Restart Windows if required.
2. Connect the unlocked iPhone with USB. Tap **Trust This Computer** and enter the device passcode if requested. Confirm Sideloadly detects the device.
3. Drag `Store-unsigned.ipa` into Sideloadly, select your phone, and enter your eligible free Apple Account. Complete authentication only inside Sideloadly/Apple's prompts, never in this source project. Keep normal signing settings and a stable bundle identifier.
4. Click Start and wait for signing and installation. Repeat with `SmoreHub-unsigned.ipa`.
5. On the iPhone, enable **Settings → Privacy & Security → Developer Mode** if requested, restart, and confirm. If developer-app trust is requested, use **Settings → General → VPN & Device Management**, select the developer identity, and complete trust/verification. Labels may vary by iOS version.
6. Launch each app from the Home Screen. In Store, request notifications, allow alerts/sounds/badges, then send a ten-second test and lock the phone. Check notification previews, Focus, Silent Mode, and Scheduled Summary settings if needed.

Free signing normally expires after about **7 days**, and normally permits **3 sideloaded apps installed simultaneously**; these two apps consume two slots. Refresh before expiry. Sideloadly's automatic refresh requires its helper running and the Windows PC available, plus USB or correctly configured Wi-Fi device pairing. Do not assume refresh occurs while the PC is off or unreachable. If Apple authentication or Sideloadly changes block signing, consult its official FAQ/current release notes; installation on a particular account/device is not guaranteed by this source project.

Update with the same Apple Account, bundle identifier, and installation identity where possible. Export JSON backups before updating. Avoid uninstalling: uninstalling deletes local data. Sideloadly may adjust identifiers during free signing; keep its settings consistent between updates.

Official references: [Sideloadly](https://sideloadly.io/), [Sideloadly FAQ](https://sideloadly.io/faq), [Apple local notifications](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app), [Apple Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device), [GitHub Actions billing](https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions).

## Notification behavior and Apple limitations

- These are **local notifications**, never remote push. No APNs entitlement, server, background loop, or paid capability is used.
- Store uses a conservative 60 pending-request budget with a separate stable test identifier (61 maximum during normal use). The platform has historically allowed around 64 pending local requests. Manual reminders consume slots, and repeating reminders consume one slot each.
- A batch contains at most 60 randomized, precomputed one-time requests. They may deliver when locked, backgrounded, or closed while provisioning remains valid, subject to iOS. **No endless random stream while closed**: refill after the batch finishes. The app does not secretly regenerate on launch or duplicate requests. Refill replaces remaining order requests; reminders remain intact.
- Editing a reminder uses the same identifier to replace its request. Pausing/deleting cancels it. Cancel-all cancels OS requests and delivered alerts but retains reminder definitions; saving a retained definition schedules it again. The pending list is the OS queue, not a promise of delivery.
- One-time/daily/weekly reminders use calendar triggers at minute precision. Daily/weekly times float with the device's local time zone. Model previews use Calendar's next-time/first-repeat DST policy; iOS owns actual calendar-trigger delivery. Test DST/time-zone changes on device. Random intervals use elapsed seconds instead.
- Permission denial produces a message and a Settings link. Foreground alerts display as banners. Badges use the batch index (not an unread counter) and clear when the app becomes active.
- **iOS does not let you replace the app name or small notification app icon dynamically with arbitrary user-selected branding.** The store name is notification content; the photo is an attachment whose layout iOS controls. The Home Screen name/icon are fixed to Store and Smore Hub at build time. No Shopify/Google/YouTube logos or screenshot imagery are bundled.
- Personal data is app-local, with no sync. iOS device backups may include it under the user's device-backup settings. This app is not cryptographically bound to one phone; if its source/IPA is shared and signed elsewhere, it can run there too. It sends nothing to other phones.

## Project layout

```
.github/workflows/build-ios.yml  # Swift tests → two physical-device builds → IPA artifacts
project.yml                      # two application targets generated by XcodeGen
Package.swift                    # portable Foundation logic tests
Shared/Core/Models.swift         # validated Codable models, planning, persistence
Shared/UI/Support.swift          # local store, native photo picker, Files JSON backups
Store/                           # SwiftUI views + UserNotifications manager + assets
SmoreHub/                        # SwiftUI dashboard, editors, Charts + assets
Tests/                           # model/schedule/persistence XCTest cases
DEVICE-CHECKLIST.md
TROUBLESHOOTING.md
VALIDATION.md
```

On a Mac, `swift test`, `xcodegen generate`, then the xcodebuild command from the workflow. No Swift packages or paid libraries are needed by the applications. The Swift package only tests shared Foundation code.