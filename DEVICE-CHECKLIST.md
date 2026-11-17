# Required physical-iPhone acceptance checks

These are manual tests, not claims of completed testing.

## Store

- Fresh install: deny notification permission; starting/testing must explain the denial. Enable it in iOS Settings, return, and confirm status updates.
- Send ten-second test in foreground, background, and with phone locked. Verify sound/badge with permitted settings; tap the alert and confirm Upcoming opens.
- Set minimum/maximum gap to 5/10 seconds, amount to 20/30, batch size to 5. Refill. Confirm five requests, bounded random times, amounts, and optional photo attachment. Refill again: confirm replacement rather than ten requests.
- Stop order alerts: verify manual reminders remain. Swipe-cancel one queued request; cancel all and verify the list empties and badge clears.
- Create a future one-time reminder, edit its title/time, confirm one request remains, tap its alert, and confirm its editor opens. Pause it, then enable/save it again. Delete and verify it is removed from OS queue and saved definitions.
- Schedule daily and weekly reminders, check their next dates. Change device time zone, cross DST gaps/repeated hours, and check wall-clock recurrence and delivery on the installed iOS version.
- Fill the available slots, add another reminder, verify a clear capacity error. A test may use one reserved slot. Concurrent refill buttons must not duplicate requests.
- Force-close after scheduling, lock and wait; verify iOS delivers the queued alerts. After a batch expires verify it does not claim infinite delivery; refill in-app.
- Change name/photo/sound/badge and refill; verify new alerts reflect it. Confirm fixed app identity remains Store.
- Relaunch: settings and reminders survive. Export backup to Files, modify data, import backup, verify restored data, canceled old queue, and explicit rescheduling. Cancel an import and select corrupt/wrong-app JSON; original data must remain.

## Smore Hub

- Test all five tabs, light/dark/device themes, portrait/landscape, large text, VoiceOver labels, and native refresh gesture.
- Edit each metric and status in each range. Verify changing 28-day values leaves 7/90/365-day values unchanged. No number count-up animation.
- Change profile/name/subscriber count/currency/avatar/goal. Relaunch and confirm persistence.
- Add/edit/delete Short/Video/Live/Post entries, pick/remove thumbnails, search, filter, expand cards, and compare counts.
- Add/edit/delete sample comments; change author/time/text/reply; toggle hearts and unanswered filter; relaunch and confirm persistence.
- Open Analytics and Earn. Verify charts and revenue remain explicitly illustrative/sample; no real publishing/payment is offered.
- Export/import JSON. Reject corrupt or wrong-app backups without losing current data. All functions should work offline.

## Installation lifecycle

- Install both IPAs with free signing. Record iOS/Sideloadly versions and any account restrictions.
- Refresh/update each using same signing identity and bundle ID; verify saved data remains. Keep independent JSON exports.
- Validate seven-day refresh behavior before relying on future alerts. Never assume notifications remain reliable after signing expiration.
