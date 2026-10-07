# Harmoniq

A Flutter music player with native audio controls for local files and online YouTube audio.

## Listening

1. Tap **Find your next song**, choose a mood, or open Search.
2. Search for a song/artist, or paste a YouTube/YouTube Music link.
3. Select a result. Harmoniq opens its own Now Playing screen with artwork, queue, seek, favorite, shuffle/repeat and play/pause controls.

There is no embedded video, hidden WebView, or external YouTube app handoff. The search result list becomes the queue. Online and local tracks use the same `just_audio` engine and Android background-media integration.

## How online playback works

- On Android, a MethodChannel calls the embedded yt-dlp/Python runtime for bounded flat search metadata. An optional YouTube Data API key can instead supply metadata. Other native platforms do not have on-device extraction support.
- Only the selected video ID is resolved with `YoutubeDL.extract_info(..., download=False)`; an HTTPS audio-only format and required playback headers are passed to the existing `just_audio` engine. No media download operation is called.
- Resolved signed URLs and headers are temporary and never persisted in songs/favorites or deliberately printed in application logs. Playback errors can refresh once with position preservation; provider-denied 403 errors do not auto-retry.
- Loading and playback errors are visible. Pause while loading is respected; skip/stop/dispose invalidate older requests so stale work cannot restart playback.
- YouTube song IDs remain strings, separate from local numeric IDs, preventing queue/catalog/favorite collisions.

**This playback integration is unofficial.** It is not the YouTube Music API or a Premium integration. Streams may fail because of service changes, expired links, regional/age restrictions, throttling or authentication requirements. No user cookies, credentials, proxies, custom challenge solvers, or access-control bypass mechanisms are configured. The packaged yt-dlp runtime lacks a bundled external JavaScript/EJS runtime, so extraction is not universally reliable. No video fallback is used. Review provider terms and media rights before distributing or using online features commercially.

### Known playback blocker (2026-09-12)

The reported Proximity track `SMs0GnYze34` currently fails audio delivery with HTTP 403. A manifest can resolve even when its media cannot be fetched. The MP4 library download produced zero bytes before the deadline. A WebM prefix request returned 206, but both a subsequent full request and a first full request from a fresh manifest returned 403 with zero bytes. Therefore neither format switching nor temporary-file buffering has been validated as a fix. The app now distinguishes provider denial when the Dart error payload includes an HTTP status, without exposing signed URLs. The installed just_audio Android plugin often logs HTTP 403 natively but forwards only `Source error` to Dart; those cases correctly remain generic rather than inventing a cause. Do not treat passing unit tests, a successful build, or a small prefix download as proof of working YouTube audio playback.

## On-device yt-dlp migration status (2026-10-05)

The **Android implementation is integrated**, replacing `youtube_explode_dart` with direct calls into the Python runtime embedded in `dev.ffmpegkit-maintained:yt-dlp-android:2.0.2`. Its public Java wrapper is download-oriented and is not used for extraction. An Android x86_64 emulator returned search metadata and one selected HTTPS audio-only format, but other selections failed; **audible playback and local/background behavior have not been validated on a physical phone**. There is no backend or download feature.

See [the migration assessment](docs/yt-dlp-migration-assessment.md) for upstream evidence, observed emulator results, release sizes, limitations, third-party notices and exact physical-phone install/check steps.

## Run with Flutter CLI and a physical Android phone

Android Studio is not required. Install Flutter, an appropriate JDK, Android SDK command-line tools/platforms/build-tools and platform-tools (ADB), then verify `flutter doctor -v` and `flutter devices`. Enable USB debugging on the phone and accept its authorization prompt.

```sh
flutter pub get
flutter run -d DEVICE_SERIAL
```

For this Windows environment, a clean dependency registration initially failed while creating desktop plugin symlinks. The Android-only retry succeeded using command-scoped flags, without changing Windows Developer Mode or global Flutter settings:

```bash
# Git Bash; values apply only to this shell/process tree.
export FLUTTER_LINUX=false FLUTTER_WINDOWS=false
flutter pub get
flutter run -d DEVICE_SERIAL
```

PowerShell equivalents are `$env:FLUTTER_LINUX = 'false'` and `$env:FLUTTER_WINDOWS = 'false'`. These flags are not needed when normal dependency registration already succeeds.

Optional official **metadata** API mode (does not grant official audio-stream access):

```sh
flutter run --dart-define=YOUTUBE_API_KEY=YOUR_RESTRICTED_KEY
flutter build apk --release --dart-define=YOUTUBE_API_KEY=YOUR_RESTRICTED_KEY
```

Enable YouTube Data API v3 in Google Cloud. Never commit a real key. Client `dart-define` values are bundled and are not secrets; apply suitable application/API restrictions, quota limits, or use an authenticated backend for production credential protection.

## Platforms

- **Android:** primary target; local MediaStore scanning, native online audio and media notifications.
- **Web:** UI preview and optional official metadata search; online audio resolution is explicitly unsupported due to browser/network restrictions. No iframe or public CORS proxy fallback.
- **iOS/macOS:** on-device yt-dlp extraction is not packaged; no native online playback is claimed.
- **Windows/Linux:** on-device yt-dlp extraction is not packaged, and no desktop `just_audio` backend is configured.

Windows Flutter plugin development may require symlink support. The project does not change machine settings automatically.

## Existing library

Local scanning remains off the Android UI thread, lists remain lazy/cached, and progress updates are isolated from full-screen rebuilds. Saved favorites from the removed Jamendo source remain unavailable legacy metadata, not silently deleted or converted into unrelated YouTube tracks.

## Download the latest Android build

The current arm64 Android release APK is available at [downloads/harmoniq-latest.apk](downloads/harmoniq-latest.apk). Verify its SHA-256 using `downloads/harmoniq-latest.apk.sha256`. This release is debug-signed and supports arm64-v8a; it is not a Play Store-ready production-signed package. The final release APK was installed and its Home, Search, Music and Library screens were smoke-tested on a physical Android phone; local scanning/playback was not verified on that APK. Online YouTube audio returned HTTP 403 for two public tracks during device checks. A successful build does not guarantee online stream delivery.

## Checks

```sh
flutter analyze
flutter test
flutter build apk --release
flutter build web --release
```

Tests cover source-aware identity/serialization, temporary URL exclusion, resolver failure/races, loading/pause/stop/retry, queues, local scanning, search routing, responsive layouts and reduced motion. Tests use fake transports/players; distinguish these from live device playback verification.

On 2026-10-05, clean Android CLI validation passed analysis and **119 Flutter tests**. Debug APK, release ABI-split APKs and release AAB built. The migrated arm64 release APK is **46.49 MiB** (+25.95 MiB versus the previous baseline) and the AAB is **74.86 MiB** (+19.19 MiB). Gradle lint passed after removing an existing nonexistent manifest receiver and correcting ignored local SDK property paths; the Android JVM test task had no sources. Only an emulator was connected; no physical-phone installation or audible playback is claimed. See the assessment for ABI limits and install commands. Release artifacts still use a debug signing certificate.

## Main components

- `youtube_catalog.dart`: metadata discovery and bounded caching.
- `yt_dlp_channel.dart` / `youtube_audio_stream_resolver.dart`: Android metadata/audio bridge and transient stream boundary.
- `audio_service.dart`: shared native playback, queue and library state.
- `now_playing_screen.dart` / `mini_player.dart`: native audio UI.

Harmoniq is independent and is not affiliated with or endorsed by YouTube or Google.
