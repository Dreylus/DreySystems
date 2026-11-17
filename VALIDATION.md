# Verified build status

Both native apps compiled and packaged successfully in [GitHub Actions run #6](https://github.com/Dreylus/DreySystems/actions/runs/44029974703) on November 17, 2026.

- Source commit: `9f8055160f507c987c0c6a1e829da18298902f1b`.
- macOS 15 runner, Xcode 16.4, iPhoneOS 18.5 SDK, minimum deployment target iOS 17.
- All 8 shared Foundation XCTest cases passed, with 0 failures.
- Store: Release device compilation, arm64/iOS verification, IPA packaging, and artifact upload passed.
- SmoreHub: Release device compilation, arm64/iOS verification, IPA packaging, and artifact upload passed.
- Downloaded both artifact ZIPs to Windows. Independently verified their SHA-256 checksums, ZIP integrity, Payload paths, bundle Info.plists, compiled assets, Mach-O arm64 headers, and LC_BUILD_VERSION platform IOS (2), rather than simulator (7). No provisioning profile is embedded.
- Source Swift syntax parsing, XcodeGen/workflow YAML validation, asset catalog checks, and all six workflow Bash syntax checks passed locally.

## Downloads

- [Store unsigned IPA artifact](https://github.com/Dreylus/DreySystems/actions/runs/44029974703/artifacts/14305525124)
- [Smore Hub unsigned IPA artifact](https://github.com/Dreylus/DreySystems/actions/runs/44029974703/artifacts/14304965967)

GitHub artifact ZIPs contain the unsigned IPA plus its checksum. Artifact retention is seven days; rerun the workflow to regenerate later. Separate extracted IPA files are also supplied with this delivery. They need signing using Sideloadly before installation.

## Remaining device checks

No simulator UI review, iPhone installation, permission prompt, notification delivery, Focus behavior, DST/time-zone delivery, free-account signing, or seven-day refresh has been tested on a physical device. Passing compilation and logic tests does not establish those outcomes. Follow DEVICE-CHECKLIST.md after installing.

Only a harmless Xcode warning about skipped AppIntents metadata extraction was present in the inspected successful app logs; these apps do not use App Intents. Actions v4 steps also print Node 20 deprecation notices while successfully running under the runner's Node 24 compatibility behavior.

## SHA-256

- `Store-unsigned.ipa`: `bd6982bad555b54689fbd4d4701dcb8498fe52c3a593df17799330b53202b87b` (215,765 bytes).
- `SmoreHub-unsigned.ipa`: `089a900c8102d676b7363776a784c86d40c4e9e52c8b9f4cfa85589796b251e0` (301,703 bytes).