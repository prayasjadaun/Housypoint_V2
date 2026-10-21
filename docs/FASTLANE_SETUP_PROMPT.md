# Prompt: Set up Fastlane + Shorebird release automation for this Flutter app

Paste everything below into Claude Code (or another AI) running inside the target app's
repository. It sets up the exact same iOS + Android release pipeline that is already
working in the "Housy One" app, reusing the same Apple Developer team and Google Play
Console account credentials (only the per-app identifiers differ).

---

## Context

This Flutter app belongs to the same organization as another app called "Housy One",
which already has a working release pipeline: `shorebird release` (builds + publishes a
Shorebird release) followed by `fastlane` (uploads the build to App Store Connect /
Google Play Console). I want you to replicate that exact setup in **this** repo.

Before you start, ask me for these values if they aren't already obvious from the repo
(check `ios/Runner.xcodeproj` / `android/app/build.gradle` for identifiers first):

- iOS bundle identifier (e.g. `com.housypoint.xyz`)
- Android package name (e.g. `com.housypoint.xyz`)
- App display name

These values are **shared across all our apps** (same Apple team / same Play Console
account) — use them as-is, do not ask me for them again:

- Apple Team ID: `4Y73GJ7TRJ`
- App Store Connect API Key ID: `4AAL989F9Q`
- App Store Connect API Issuer ID: `ac2d5dbf-22eb-4f97-89e2-4eed9aa81ff6`

Two secret files are **NOT** included in this prompt and must be supplied by me manually
(do not ask me to paste their contents, just tell me where to put them and stop):

- `ios/fastlane/AuthKey_4AAL989F9Q.p8` — the same App Store Connect private key used by
  the other app. I will copy it from `housy_one/ios/fastlane/AuthKey_4AAL989F9Q.p8`.
- `android/fastlane/play-store-credentials.json` — the same Google Play service account
  key (`play-store-fastlane@housypoint-fastlane.iam.gserviceaccount.com`). I will copy
  it from wherever I've stored it (originally downloaded to `~/Downloads/`). This service
  account already has account-wide "Release to production" / "Release apps to testing
  tracks" / "Manage testing tracks" permissions granted in Play Console, so it already
  has access to every app under this developer account — including apps created after
  today — no per-app grant step is needed.

---

## iOS setup

1. Ensure `ios/Gemfile` contains fastlane:

```ruby
source "https://rubygems.org"

gem "fastlane"
```

Run `cd ios && bundle install`.

2. Create `ios/fastlane/Appfile`:

```ruby
app_identifier("<IOS_BUNDLE_ID>")
team_id("4Y73GJ7TRJ")
```

3. Create `ios/fastlane/Fastfile` with **exactly** this content (it's generic, no
   per-app values are hardcoded in it):

```ruby
default_platform(:ios)

platform :ios do
  def asc_api_key
    app_store_connect_api_key(
      key_id: ENV["ASC_KEY_ID"],
      issuer_id: ENV["ASC_ISSUER_ID"],
      key_filepath: ENV["ASC_KEY_FILEPATH"],
    )
  end

  def latest_ipa
    Dir[File.expand_path(File.join(__dir__, "..", "..", "build", "ios", "ipa", "*.ipa"))].max_by { |f| File.mtime(f) }
  end

  desc "Upload the latest `shorebird release ios` build to TestFlight"
  lane :beta do
    ipa_path = latest_ipa
    UI.user_error!("No .ipa found in build/ios/ipa — run `shorebird release ios --export-method app-store` first") unless ipa_path

    upload_to_testflight(
      api_key: asc_api_key,
      ipa: ipa_path,
      skip_waiting_for_build_processing: true,
    )
  end

  desc "Upload the latest `shorebird release ios` build to App Store Connect (App Store review)"
  lane :release do
    ipa_path = latest_ipa
    UI.user_error!("No .ipa found in build/ios/ipa — run `shorebird release ios --export-method app-store` first") unless ipa_path

    upload_to_app_store(
      api_key: asc_api_key,
      ipa: ipa_path,
      submit_for_review: false,
      automatic_release: false,
      force: true,
      skip_screenshots: true,
      precheck_include_in_app_purchases: false,
    )
  end
end
```

   Important: keep the `File.expand_path(...)` wrapper in `latest_ipa`. Without it, the
   relative `..`/`..` path breaks depending on the shell's working directory when
   fastlane is invoked (this was a real bug we hit and fixed).

4. Create `ios/fastlane/.env.default` (commit this one) **and** `ios/fastlane/.env`
   (gitignored, actually used):

```
# Copy this file to `.env` (gitignored) and fill in ASC_KEY_FILEPATH.
# ASC_KEY_ID and ASC_ISSUER_ID below are already correct for the
# "App Store Upload Key" (Admin, works for all apps on this team).

ASC_KEY_ID=4AAL989F9Q
ASC_ISSUER_ID=ac2d5dbf-22eb-4f97-89e2-4eed9aa81ff6
ASC_KEY_FILEPATH=./fastlane/AuthKey_4AAL989F9Q.p8
```

   Note the path is `./fastlane/AuthKey_...p8`, not `./AuthKey_...p8` — fastlane is
   invoked from the `ios/` directory (not `ios/fastlane/`), so the path must be relative
   to `ios/`.

5. Stop and tell me to manually copy `AuthKey_4AAL989F9Q.p8` into `ios/fastlane/`.

6. Create `ios/fastlane/metadata/en-US/release_notes.txt`:

```
Bug fixes and performance improvements.
```

7. Add to `ios/.gitignore` (create the file if it doesn't exist):

```
# Fastlane
fastlane/.env
fastlane/*.p8
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots
fastlane/test_output
```

8. Create `release_ios.sh` at the repo root:

```bash
#!/bin/bash
# Build a Shorebird release and upload it via Fastlane.
# Usage: ./release_ios.sh [beta|release]   (default: release)
set -euo pipefail

LANE="${1:-release}"
cd "$(dirname "$0")"

shorebird release ios --export-method app-store

cd ios
bundle exec fastlane "$LANE"
```

   Make it executable: `chmod +x release_ios.sh`.

9. If this app doesn't already have a `shorebird.yaml` at the repo root, run
   `shorebird init` to register it and generate one.

10. Confirm the app with this exact bundle identifier already exists in App Store
    Connect (fastlane uploads builds to an existing app entry, it does not create new
    apps).

---

## Android setup

1. Ensure `android/Gemfile` contains fastlane:

```ruby
source "https://rubygems.org"

gem "fastlane"
```

Run `cd android && bundle install`.

2. Create `android/fastlane/Appfile`:

```ruby
json_key_file("./fastlane/play-store-credentials.json")
package_name("<ANDROID_PACKAGE_NAME>")
```

3. Create `android/fastlane/Fastfile`:

```ruby
default_platform(:android)

platform :android do
  desc "Upload the latest release build to the Play Console internal testing track"
  lane :beta do
    upload_to_play_store(
      track: "internal",
      aab: Dir[File.expand_path(File.join(__dir__, "..", "..", "build", "app", "outputs", "bundle", "release", "*.aab"))].max_by { |f| File.mtime(f) },
      release_status: "draft",
    )
  end

  desc "Upload the latest release build to the Play Console production track"
  lane :release do
    upload_to_play_store(
      track: "production",
      aab: Dir[File.expand_path(File.join(__dir__, "..", "..", "build", "app", "outputs", "bundle", "release", "*.aab"))].max_by { |f| File.mtime(f) },
      release_status: "draft",
    )
  end
end
```

4. Stop and tell me to manually copy `play-store-credentials.json` into
   `android/fastlane/`. No Play Console access-grant step is needed — the service
   account already has account-wide release permissions covering every app under this
   developer account.

5. Add to `android/.gitignore`:

```
# Fastlane
fastlane/*.json
fastlane/report.xml
```

6. Create `release_android.sh` at the repo root:

```bash
#!/bin/bash
# Build a Shorebird release and upload it via Fastlane.
# Usage: ./release_android.sh [beta|release]   (default: release)
set -euo pipefail

LANE="${1:-release}"
cd "$(dirname "$0")"

shorebird release android

cd android
bundle exec fastlane "$LANE"
```

   Make it executable: `chmod +x release_android.sh`.

---

## After setup

Walk me through running `./release_ios.sh` and `./release_android.sh` once each and
verifying they complete without errors (watch specifically for "Could not find ipa/aab"
or "Couldn't find key" errors — both are path-resolution issues we've hit before; the
`File.expand_path` wrapper and the `./fastlane/...` prefix in `.env` are what prevent
them). Do not run either script yourself — ask me to run it and paste you the output.
