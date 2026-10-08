# On-device yt-dlp migration — 2026-10-05

> Historical baseline assessment. See [the 2026-10-07 resolver report](youtube-resolver-2026-10-07.md) for the subsequent runtime investigation, replacement bundle, and current validation. Results below describe the earlier build, not the current implementation.

## Outcome and scope

Harmoniq's Android online path has been migrated from `youtube_explode_dart` to a custom MethodChannel adapter calling the Python yt-dlp runtime embedded in `dev.ffmpegkit-maintained:yt-dlp-android:2.0.2`. The public wrapper's `execute`/`download` API is **not called**. The app has no download feature, server, second player, cookie/credential handling, DRM bypass, or persisted signed stream URL. This is a technical integration, **not verified audible playback on a physical phone**.

The repository already used YouTube, not Audius. The local MediaStore channel and `content://` scanning are retained. `Song` keeps `youtube:<videoId>` identities and the `harmoniq_favorites_v1` key; online URLs and headers are transient. Local and online sources still install into the single `AudioService`/`just_audio` player. The optional official YouTube Data API remains for metadata when a key is configured; it does not supply audio access. Web keeps its metadata-only API option; non-Android native online extraction is unsupported.

## Verified artifact and direct call

Maven Central's 2.0.2 AAR SHA-256: `d2e71858f4c144f021534e658b94d0c3616818b662c848903f1f2fe9dec4a7d0`. It bundles Chaquopy 17.0.0, Python 3.13 and yt-dlp 2026.06.09, with minSdk 24 and runtime libraries for arm64-v8a and x86_64. The wrapper's public `execute` path calls `ydl.download([url])`, ignores necessary metadata-only flags, and cannot return structured metadata or streams. Inspection of its embedded bridge and the corresponding yt-dlp source established `YoutubeDL.extract_info(url, download=False)`, `sanitize_info`, and the Chaquopy Python module/attribute bridge. The adapter uses JSON serialization to create a Python options dictionary and returns sanitized structured data; no stdout parsing or wrapper download operation is involved.

The adapter accepts a bounded query (200 characters, 1–10 flat search results), validates selected 11-character video IDs, and resolves only the selected video's direct HTTPS audio-only format. It excludes advertised DRM and non-direct protocols, prefers m4a near 144 kbps with another directly playable audio-only format as fallback, and passes selected User-Agent/Referer headers transiently to `AudioSource.uri`. It serializes native work on a single executor with four queued slots, uses yt-dlp socket timeouts and zero configured extractor retries, and masks exception text rather than logging signed URLs. Dart's 20-second timeout **does not cancel** in-progress native/Python work. The runtime can log yt-dlp warnings internally; redact logs before sharing. `WRITE_EXTERNAL_STORAGE` inherited from the AAR is removed in the merged application manifest; no media file is deliberately written. Platform/player caches and runtime extraction assets are not permanent music downloads.

## Actual emulator evidence and limitations

Android SDK CLI created and booted an Android 36 x86_64 emulator (`emulator-5554`). A temporary smoke entry point, subsequently removed, installed through ADB and reported embedded yt-dlp version 2026.06.09, Python import, `YoutubeDL` construction, `sanitize_info`, JSON and Flutter channel communication on synthetic offline metadata. With live network it returned two flat search results for `official music`. In one run, resolving the first selected ID returned an audio-only format `251` and an HTTPS `googlevideo.com` host; the signed URL was not retained in the report. Another extraction hit YouTube's sign-in challenge, and a second public ID hit an SSL record error. Search and resolution are therefore functional on that emulator for at least one selected result, **not universally reliable**. The AAR does not bundle an external JavaScript runtime or `yt-dlp-ejs` distribution; service changes can break extraction. No workaround for authentication, rate limits, region/age restrictions or access controls is included.

The emulator result is **not a physical-phone result** and does **not prove that ExoPlayer fetched media or that audio was audible**. The final production entry-point debug APK was installed and launched on the emulator, but no production-UI playback acceptance was performed. The previous recorded track `SMs0GnYze34` returned HTTP 403 for full audio delivery; an extracted format is not proof of delivery. No physical phone was attached to ADB during this work.

One bounded automatic re-resolution is attempted after a non-403 playback-event failure while playback is desired, restoring the last known position; a 403 is surfaced without automatic retry. A manual retry resolves afresh and seeks to the saved position. Source generations prevent late native results from replacing a newer selection. Native extraction has no cooperative cancellation, and the single-thread queue can temporarily delay later requests even after Dart has timed out. These behaviors require physical-device validation under network loss and source switching.

## Clean CLI validation and size impact

Windows desktop plugin symlink creation can fail without Developer Mode. These checks used process-scoped `FLUTTER_LINUX=false FLUTTER_WINDOWS=false` for Android-only work, without requiring Android Studio or changing Flutter global configuration.

| Check | Observed outcome |
| --- | --- |
| `flutter clean`, `flutter pub get` | Both completed with Android-only environment flags |
| `flutter analyze` | No issues |
| `flutter test --reporter compact` | **119 tests passed**; a preceding full run identified a paused-stream assertion that was corrected before the passing rerun |
| `flutter build apk --debug --target-platform android-arm64,android-x64` | Completed |
| `flutter build apk --release --split-per-abi` | All three Flutter ABI splits completed |
| `flutter build appbundle --release` | Completed |
| `:app:lintDebug :app:testDebugUnitTest --rerun-tasks` | **BUILD SUCCESSFUL** after removing an existing nonexistent receiver and correcting ignored local SDK property path escaping; Flutter regenerates those paths on builds, so the ignored local file must be corrected again before standalone lint; JVM unit-test task is `NO-SOURCE` |

The release build is still **debug-signed** by the existing Gradle configuration; it is not store-ready. Full Flutter tests use mocked channels/players and cannot establish media delivery or local-file behavior on a phone.

| Artifact | Migrated bytes | Migrated MiB | Previous baseline bytes | Change |
| --- | ---: | ---: | ---: | ---: |
| Debug APK | 166,607,306 | 158.89 | 128,969,391 | +37,637,915 (+35.89 MiB) |
| arm64-v8a release APK | 48,746,053 | 46.49 | 21,538,705 | +27,207,348 (+25.95 MiB) |
| armeabi-v7a release APK | 35,326,934 | 33.69 | 19,144,029 | +16,182,905 (+15.43 MiB) |
| x86_64 release APK | 50,302,497 | 47.97 | 23,088,009 | +27,214,488 (+25.95 MiB) |
| Release AAB | 78,493,413 | 74.86 | 58,371,864 | +20,121,549 (+19.19 MiB) |

MiB = bytes / 1,048,576. The 32-bit ARM split is built by Flutter but has **no matching packaged yt-dlp native runtime**; do not distribute it as an online-capable APK. For a supported phone use the arm64 split. An AAB contains all Flutter splits; verify ABI delivery/eligibility before publishing. This is a significant binary-size increase, not the AAR's compressed size alone.

## Install and physical-phone manual acceptance

Enable developer options and USB debugging, connect a phone, accept its RSA prompt, then run from the repository root in PowerShell. Do not uninstall or clear app data just to overcome a signing mismatch: that destroys saved favorites. Check ABI and Android API first (yt-dlp runtime requires Android API 24+, arm64-v8a or x86_64):

```powershell
$adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
& $adb devices -l
$serial = 'REPLACE_WITH_AUTHORIZED_PHONE_SERIAL'
& $adb -s $serial shell getprop ro.build.version.sdk
& $adb -s $serial shell getprop ro.product.cpu.abilist
& $adb -s $serial install -r -d 'build\app\outputs\flutter-apk\app-debug.apk'
& $adb -s $serial shell am start -n 'com.example.rachan/.MainActivity'
```

For a confirmed arm64 phone and compatible existing signature/version, the release-split install is:

```powershell
& $adb -s $serial install -r 'build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
& $adb -s $serial shell am start -n 'com.example.rachan/.MainActivity'
```

The `-d` on the debug installation permits a version-code downgrade from an ABI split; it does not bypass certificate mismatch. An AAB is not directly installable through `adb install`. If multiple devices appear, always pass `-s $serial`.

Record phone model/API/ABI/build, query/selected video ID, loading latency, **audible** result, and friendly error text for each check:

1. Grant and deny/retry media and notification permissions; scan at least two legitimate local files and listen, seek, pause, skip, use mini/full player and favorites.
2. Turn off Wi-Fi/mobile data; verify local `content://` playback and queue still work. Restore connectivity.
3. Submit public music queries (e.g. `Believer Imagine Dragons`, `Blinding Lights`, `Kesariya`, and a regional-language query); inspect result metadata, select one track, verify audible playback, seek, pause/resume, and skip. Try a pasted YouTube link. Record failures; a search hit or HTTPS format is not a pass for audio.
4. Switch local → online → local → online and verify the single player/queue and no stale source restart. If online fails, confirm local still plays.
5. With a real audible track, lock the screen and test notification play/pause and next/previous. Repeat online only if delivery works; do not infer controls from manifest entries alone.
6. During online playback, disable connectivity and restore it; observe one refresh, position preservation and error/retry behavior. A 403 must not loop automatically. Verify local remains usable.
7. Favorite local and online items, relaunch without wiping data, and verify stable identities. Custom playlists remain session-only in the existing app; do not claim persistence. Check app storage and redact signed URL/header values from logs.

## Distribution and notices

The wrapper is MIT; the embedded Python/Chaquopy/yt-dlp and native dependencies have their own terms. [Upstream notices](https://github.com/ffmpegkit-maintained/yt-dlp-android/blob/main/THIRD-PARTY-NOTICES.txt) identify yt-dlp (Unlicense), Chaquopy (MIT), and Python (PSF), but that current-main file is not in the 2.0.2 AAR. A complete release-specific transitive notices audit and in-app acknowledgements are **not complete**. Before distribution, inspect applicable embedded certifi/setuptools/native SSL and other license notices, set up production signing, review store and provider terms, verify supported ABIs, and obtain any required content rights. Extraction capability does not grant media rights.
