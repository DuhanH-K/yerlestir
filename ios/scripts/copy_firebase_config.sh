#!/bin/sh
set -eu

config="${SRCROOT}/Runner/GoogleService-Info.plist"
destination="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/GoogleService-Info.plist"

if [ ! -f "$config" ]; then
  echo "warning: Firebase Analytics unavailable: add the real GoogleService-Info.plist for com.yerlestir.game.yerlestir to ios/Runner."
  exit 0
fi

/usr/bin/plutil -lint "$config"
bundle_id=$(/usr/libexec/PlistBuddy -c "Print :BUNDLE_ID" "$config")
if [ "$bundle_id" != "$PRODUCT_BUNDLE_IDENTIFIER" ]; then
  echo "error: GoogleService-Info.plist BUNDLE_ID does not match Runner."
  exit 1
fi
for key in GOOGLE_APP_ID API_KEY PROJECT_ID GCM_SENDER_ID; do
  value=$(/usr/libexec/PlistBuddy -c "Print :$key" "$config")
  if [ -z "$value" ]; then
    echo "error: GoogleService-Info.plist is missing $key."
    exit 1
  fi
done

/bin/mkdir -p "${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
/bin/cp "$config" "$destination"
echo "Firebase iOS configuration validated and included in Runner."
