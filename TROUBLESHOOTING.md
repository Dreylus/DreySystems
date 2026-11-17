# Troubleshooting

**No Actions workflow appears:** `.github/workflows/build-ios.yml` must be committed at the repository root on the default branch. Check for an accidental enclosing folder or omitted hidden directory. Enable repository Actions.

**Build fails:** open the failed job's first compiler error and download the app's build-logs artifact. Record the Xcode version printed in the runner log. Fix the actual error; do not treat static Windows checks as proof of compilation. No signing secret should be required. `iphoneos` / `generic/platform=iOS` must stay selected.

**XcodeGen unavailable:** inspect Homebrew connectivity and runner image. The workflow installs it only when absent. XcodeGen and GitHub-hosted Xcode evolve; use a currently supported macOS image if `macos-15` is retired.

**No IPA artifact:** core tests or a device build/package check failed. Logs upload even on build failure. A simulator `.app` is not an installable iPhone app. The IPA structure must be `Payload/Store.app` or `Payload/SmoreHub.app`.

**Phone not detected / signing fails:** follow the current official Sideloadly FAQ. Check official desktop Apple components, USB cable, pairing, Trust, eligible account/2FA, Developer Mode, and available free-app slots. Do not disable account protections or pay for a developer plan merely to compile this source. Apple authentication changes can require a Sideloadly update; no particular free-account signing outcome was verified here.

**App no longer launches after several days:** refresh its free provisioning before expiry. Export backups when possible and avoid uninstalling. Automatic refresh needs an available PC/helper and reachable paired device.

**No notification:** check iOS notification permission, previews, Focus, Silent Mode/sound, Scheduled Summary, future time, nonempty queue, and valid app provisioning. Try the ten-second test. Batch alerts stop after their finite queue. Refill in the app. Exact timing and visual layout belong to iOS.

**Badge seems wrong:** the batch badge is the scheduled alert's ordinal, not unread count. It clears on return to the app. Refill and opening the app may change displayed counts.

**Imported reminders do not fire:** importing cancels the old queue. Open each imported reminder and save it; refill random orders separately.

**Storage/backup error:** the app reports save failures. If an existing data file cannot decode, it preserves that file and disables automatic overwrites for the session; import a valid backup to recover. Never delete/reinstall without a backup if data matters. Invalid intermediate settings may remain in memory but are not written; correct them and save/export again.

**Custom picture is not the small app icon:** expected iOS behavior. User photos change in-app images or notification attachments. The app identity is fixed at build time.
