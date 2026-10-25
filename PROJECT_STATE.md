# PROJECT_STATE.md - Lapkoyeth Active State

Last updated: 2026-10-25

## Project

- App: `lapkoyeth`, Flutter pet-care app for owners and pets.
- Workspace path: `/root/.openclaw/workspace/lapkoyeth`.
- GitHub repo: https://github.com/anton-stv/lapkoyeth.
- Current priority: finish shared Android/Web Firebase data and publish the same
  source branch to GitHub Pages.

## Web State

- Public build: https://lapkoyeth.web.app
- Firebase Web app is registered and initialized from
  `lib/core/firebase/firebase_web_options.dart`.
- Responsive desktop navigation, bounded auth forms and platform-safe images
  are implemented.
- Profile, pets, weight, health, checklists, notifications and viewed stories
  are mirrored to owner-only Firestore collections with Hive as an offline
  cache.
- Firestore rules/indexes and Firebase Hosting are deployed.
- Firebase Storage still requires the one-time **Get Started** action in the
  Firebase Console; after that deploy `storage.rules`.
- GitHub Pages CI is prepared, but the agent still needs GitHub write access to
  push the branch and enable Pages.

## Current Working Tree

Firebase/stories/community and Web work are consolidated on
`feature/web-firebase`. Do not add generated APK/ZIP/TAR artifacts or
`android/.kotlin/` to source control.

Important changed/untracked areas:

- Android Firebase setup:
  - `android/app/build.gradle.kts`
  - `android/settings.gradle.kts`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/google-services.json`
- Firebase app code:
  - `lib/main.dart`
  - `lib/core/firebase/`
  - `lib/features/auth/providers/auth_provider.dart`
- Stories:
  - `lib/models/story_model.dart`
  - `lib/features/home/providers/stories_provider.dart`
  - `lib/features/home/widgets/stories_row.dart`
  - `lib/features/home/widgets/story_viewer.dart`
  - `assets/images/stories/`
- Local database additions:
  - `lib/core/database/database_helper.dart`
- Dependency updates:
  - `pubspec.yaml`
  - `pubspec.lock`

## Firebase State

Firebase is wired into the app for the current iteration:

- Firebase Auth is used for registration/login.
- Firestore user document creation was confirmed: registration should create `users/{uid}`.
- FCM token plumbing exists through `lib/core/firebase/`.
- Android has `google-services.json`.
- Android manifest includes network access needed for Firebase.

Do not store Firebase secrets or credentials in this state file.

## Stories Direction

Stories are controlled by Firestore, but the welcome story images are local APK assets.

Firestore controls:

- Feature flag: `app_config/features.storiesEnabled`
- Stories collection: `stories`
- Welcome story document id: `stories/welcome`
- Expected useful fields:
  - `enabled`: boolean
  - `title`: string
  - `subtitle`: string
  - `type`: string, one of `promo`, `mine`, `friend`
  - `sortOrder`: number
  - optional remote images for non-welcome stories: `imageUrl`, `previewImageUrl`

Welcome story local assets:

- Full story image: `assets/images/stories/welcome_story.webp`
- Preview image: `assets/images/stories/welcome_preview.webp`

Current behavior:

- `stories/welcome` uses local WebP images even if Firestore controls the story data.
- Stories are loaded only when `app_config/features.storiesEnabled == true`.
- Viewed story ids are stored locally through `DatabaseHelper`.
- Viewed stories should render muted/monochrome and move after unviewed stories.

## Recent APK Artifacts

Project-root APKs from recent test builds:

- `lapkoyeth-welcome-story-1.0.1-alpha.1-arm64.apk`
- `lapkoyeth-no-index-stories-arm64.apk`
- `lapkoyeth-stories-viewed-images-arm64.apk`

Latest checked build output:

- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- Size was around 21 MB, suitable for Telegram delivery.

## Verification Habit

Before sending an APK:

1. Run `flutter analyze`.
2. Run `flutter test`.
3. Build an arm64 release APK, preferably split per ABI when size matters.
4. Confirm APK size before sending to Telegram.

Useful build command:

```bash
flutter build apk --release --target-platform android-arm64 --split-per-abi
```

## Next Steps

- Enable Firebase Storage in the console and deploy `storage.rules`.
- Connect GitHub write access, push `feature/web-firebase`, merge to `main` and
  select GitHub Actions as the Pages source.
- Run `tools/firebase-migration/migrate-users.mjs` using the steps in
  `FIREBASE_DEPLOY.md` to backfill public profile/search fields.
- Test Community search with two Firebase accounts; the signed-in account is
  intentionally excluded from its own search results.
- Validate the current welcome story build on a real Android device.
- Confirm Firestore document values for `app_config/features` and `stories/welcome`.
- Decide whether to keep remote image support for future non-welcome stories or make all first-run stories local assets.
- Commit the Firebase/stories iteration once Android testing is good.
