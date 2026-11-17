# Install your two apps from Windows

Both apps built successfully: [build results](https://github.com/Dreylus/DreySystems/actions/runs/44029974703).

1. Use the supplied `Store-unsigned.ipa` and `SmoreHub-unsigned.ipa`. Alternatively, download the two `*-unsigned-IPA` artifacts from the build results and extract each artifact ZIP.
2. Install [Sideloadly for Windows](https://sideloadly.io/) and its officially linked Apple iTunes/iCloud components. Connect your unlocked iPhone by USB, trust the computer, and check that Sideloadly detects it.
3. Drag an IPA into Sideloadly, choose the phone, enter your eligible free Apple Account in Sideloadly, and click Start. Repeat for the other IPA. Enable Developer Mode and developer-app trust on the phone if iOS prompts you. Launch each app from the Home Screen.
4. In Store → Settings, request notification permission. Send the ten-second test, lock your phone, and confirm it arrives. Customize the store and refill a batch. Smore Hub opens directly into its editable offline dashboard.

These files are unsigned: tapping an IPA on the phone will not install it. Free signing normally needs renewal within seven days and normally permits three installed sideloaded apps. These two use two slots. Check the [official Sideloadly FAQ](https://sideloadly.io/faq) for current account and refresh requirements. Sideloadly authentication and physical-device behavior have not been verified here.

Keep JSON backups from each app before updating. Use the same signing identity and bundle IDs for future updates, and avoid uninstalling if you want to retain local data. See README.md for detailed steps and DEVICE-CHECKLIST.md for testing.