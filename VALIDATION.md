# Validation status

Windows authoring environment: Python and Git available; Swift, Xcode, xcodebuild, macOS SDKs, and an iPhone execution target unavailable. No repository was attached, and no GitHub destination was supplied at packaging time.

## Checks actually executed

- PASS: Tree-sitter Swift syntax parsing for all 7 Swift files. This is syntax parsing, not Swift type checking or compilation.
- PASS: Workflow and XcodeGen YAML parse; both application source directories, schemes, bundle IDs, manual/main triggers, read-only permission, test dependency, and two-app matrix verified.
- PASS: Asset catalog JSON and both original 1024×1024 RGB app icons verified; no alpha channel.
- PASS: Bash syntax checking for all 6 workflow run scripts. macOS commands were not executed on Windows.
- PASS: Static workflow assertions for unsigned physical-device build, Payload packaging, platform/architecture verification, and ZIP integrity check.
- PASS: Source audit for native SwiftUI/UserNotifications/Charts implementation; no WebView, network SDK, background task entitlement, core TODO, or fatalError placeholder.

## Checks NOT executed

- Swift type checking, unit-test execution, XcodeGen project generation, or iOS compilation.
- GitHub Actions execution and resulting unsigned IPA verification.
- UI rendering on simulator, notification delivery, sideloading/free-account authentication, device layouts/accessibility, or seven-day refresh behavior.

Eight XCTest cases are included for random scheduling/capacity, invalid ranges, stable reminder IDs/duplicates, create-edit-delete persistence, calendar recurrence/past dates, DST, independent dashboard ranges/comment persistence, and corrupt backups. The CI core-tests job must pass before app builds. Permission denial and notification queue behavior need the physical-device checklist.

Syntax parsing and static assertions cannot establish that the apps compile or work on an iPhone. The workflow and DEVICE-CHECKLIST.md are the remaining verification path.
