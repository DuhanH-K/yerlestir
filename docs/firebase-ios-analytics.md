# YERLEŞTİR iOS Firebase Analytics

This integration initializes Firebase only on iOS and enables Analytics collection
after initialization. It never logs `first_open` manually. Android has no Firebase
initialization, Google Services configuration, or Gradle change.

## Required real Firebase configuration

In the intended Firebase project, enable Google Analytics and register the iOS app
with Bundle ID `com.yerlestir.game.yerlestir`. Download its real config file to
`ios/Runner/GoogleService-Info.plist`. Do not substitute an Android config or a
different app's plist. No Firebase project is selected by the source code.

Runner's **Firebase iOS Config** build phase validates this file's Bundle ID,
required fields and plist syntax, then copies it into Runner.app for every build
configuration. No separate Xcode resource entry is needed. If the file is absent,
the build logs a warning and the game still starts, but Analytics is unavailable.
The file must also reach the Codemagic checkout, either through Git or an existing
secure workflow step before the Xcode build starts. There is no codemagic.yaml.

The project already uses Flutter's Swift Package Manager integration; no Podfile
is required or added. Both Firebase plugins require iOS 15.0, matching Runner.
Version, build number, signing, ATT, UMP, AdMob and gameplay are unchanged.

## Validate before enabling an Ads conversion

1. Build and launch on iOS with the real config. Debug logs must show
   `[Analytics][iOS] Firebase initialized; collection enabled.`
2. For a local debug build, add `-FIRDebugEnabled` to the Xcode launch arguments
   and inspect Firebase Analytics DebugView. Never bake this into release launch
   settings. Use a fresh installation to validate automatic `first_open`.
3. In Firebase project settings, enter the real App Store ID of YERLEŞTİR.
4. Link the Firebase/Google Analytics property to the intended Google Ads account.
5. Import the iOS `first_open` event as the app install conversion in Google Ads
   and select it for the intended iOS app campaign. Linking alone does not finish
   conversion setup. Console permissions, event delivery and campaign attribution
   cannot be verified by local source code.

References:
- https://firebase.google.com/docs/ios/setup
- https://firebase.google.com/docs/analytics/debugview
- https://support.google.com/google-ads/answer/6397604
- https://support.google.com/google-ads/answer/6366292
