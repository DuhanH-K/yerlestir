# AdMob release device checklist

Automated validation: flutter analyze clean; 82 tests pass with ADS_TEST_MODE=false.
All native SDK channels in tests are mocked; no live production ad requests.
No USB device was listed by adb devices. No iPhone or IPA validation performed.

Android: use a debug build with default Google test units. iPhone: use a debug
build with test units, or register the device as a test device in AdMob before
using a TestFlight release. Release cannot be switched to Google demo unit IDs.

For each platform:
- Start from fresh consent state on a test device; do not reset production users.
- Keep UMP open for 30 seconds; verify one consent flow and no premature load.
- Finish one round with at least 3 moves: rounds_below_2, no interstitial.
- Finish another qualifying round: one show, if loaded and app foreground.
- Finish two more rounds before 90 seconds from ad_showed: cooldown_90s.
- After 90 seconds and eligible rounds: one show; no duplicate show.
- Close rewarded before earning: no rescue/hint. Complete it: one reward only.
- Background while rewarded loads: no delayed show on return; tap again explicitly.
- Open privacy options, background/resume, change selection: no parallel UMP init
  and no old-consent ad reuse. Return from existing ATT prompt if shown.
- Disable/enable Wi-Fi/network: load_fail then bounded 30/60/120 second backoff,
  no rapid request loop or requests while backgrounded.
- Navigate menu/game/results repeatedly; observe banner request/disposal logs,
  fitting width, no overlap with gameplay controls and no duplicate AdWidget.
- Stay on a screen for a long session: visible banner refresh by SDK, no manual
  refresh after successful loading. Check iPhone safe areas and actual impressions.
- With real Firebase plist, confirm automatic first_open remains available.

Device results must be recorded separately; the checklist itself is not PASS.
