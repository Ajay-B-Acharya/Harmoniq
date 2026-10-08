# YouTube resolver investigation and validation — 2026-10-07

## Baseline and scope

The starting working tree was clean on `release/ui-discovery-yt-dlp`, commit `97d446a`. Checkpoint branch `checkpoint/player-before-resolver-20261007` preserves that commit; an empty checkpoint commit was unnecessary.

This checkout **already removed `youtube_explode_dart`** and calls `YtDlpAdapter.kt` through `com.example.harmoniq/yt_dlp`. The earlier migration document describes that integration, not proof of reliable physical-device audio. The requested architecture is therefore partly present at the baseline. No backend or second player is required by that architecture.

The shared player is `lib/services/audio_service.dart`, holding one `just_audio.AudioPlayer`. Local scanning uses `com.example.harmoniq/local_music` → `MainActivity.fetchLocalSongs` → Android MediaStore → `content://media/external/audio/media/<id>` → existing local `Song` → `AudioSource.uri`. `MainActivity` extends the existing `AudioServiceActivity`; background playback remains `just_audio_background`. Local permissions, scanner, source conversion, queue, playlists, favorites, shuffle, repeat and player engine are outside the resolver replacement scope.

Baseline CLI: Flutter **3.47.6**, Dart **3.13.5**, Java **17.0.19**. `flutter analyze` passed; `flutter test --reporter compact` passed **120 tests** before edits. Android-only process environment flags `FLUTTER_WINDOWS=false` and `FLUTTER_LINUX=false` avoid unrelated desktop plugin setup. No Flutter downgrade or unrelated package upgrade.

## Retired youtube_explode_dart path

Evidence: `git show f38a7cd:lib/services/youtube_audio_native.dart`, `youtube_metadata_native.dart`, that revision's `pubspec.lock`, and locally cached package source for **3.1.0**.

- **Search:** `YoutubeExplode.search.search(query)` parsed one public results page; the app mapped video ID, title, author, high-resolution thumbnail and duration. The metadata-only custom HTTP client used `Harmoniq/1.0 (public YouTube metadata)`, HTML Accept and English Accept-Language headers, disabled redirects, and closed on a failed request to stop library retries.
- **ID:** search used `video.id.value`. Pasted links used the app's exact host allowlist and eleven-character ID validation in `YoutubeLinks.videoIdFromInput`; watch, short, embed and live paths were supported.
- **Stream info:** a separate standard `YoutubeExplode()` called `videos.streamsClient.getManifest(videoId)` with a 20-second timeout. No JavaScript solver was injected.
- **Library internals:** `StreamClient.getManifest` defaults to `androidSdkless`, checks the first stream with HEAD, and falls back to the TV client if the default produced no streams. Safari is added only when a JavaScript solver exists. Signature/n challenge solving is conditional on that solver. A successful HEAD of one stream is not evidence that the separately selected audio format can be delivered to ExoPlayer.
- **Format:** app filtered `manifest.audioOnly`, preferred MP4-container audio, then selected highest bitrate. It did not use a fixed format ID.
- **Returned URL:** `candidates.first.url` was returned unchanged after HTTPS/host/user-info validation. The exact failing signed URL was not retained in the repository and is not fabricated here.
- **Headers:** extraction used the library's default Chrome/96 User-Agent, `CONSENT=YES+cb` cookie and Accept/Accept-Language values. The retired resolver returned only a URI; it did not return those headers to `just_audio`. These are observations of old code, not suggested fixes.

### HTTP 403 evidence and limits

The user's supplied physical-device observation is that public-track media requests returned HTTP 403 after discovery and selection succeeded. The baseline migration document additionally records `SMs0GnYze34` receiving 403 for full audio delivery. `test/native_youtube_audio_test.dart` contained a **synthetic** nested ExoPlayer `responseCode: 403` regression fixture for that ID; a fixture is not a device log.

The initial filtered ADB log snapshot in this session contained no retained ExoPlayer 403 stack trace. The installed app initially displayed an unavailable-audio state for Little Mix's Black Magic. That UI state alone does not establish an HTTP status or identify which installed resolver produced it.

**Conclusion:** the reported media request was rejected by the server; metadata discovery and a syntactically valid signed URL do not establish playable delivery. The precise reason (signature/challenge state, URL expiration, client binding, network policy, or other server decision) is **not proven by the retained evidence**. No random header, cookie, User-Agent or retry workaround is justified by this evidence. The former extraction path is abandoned for playback, rather than patched.

## Baseline device observations

An authorized Motorola **moto g45 5G**, Android API **35**, reports `arm64-v8a,armeabi-v7a,armeabi`. The pre-existing installed app was version 1.0.0 / code 1, updated 2026-10-07 19:06:13; it is not assumed to be byte-identical to a newly built checkout.

Before resolver changes were installed, an existing local song progressed to 1:34; pause/resume toggled correctly; seek moved to 2:53; next selected the second local track; previous at the beginning returned to the first. These are UI/native behavioral observations, **not independently heard audio**. Device input was paused when another app became foreground. Baseline behavior does not replace acceptance testing of the final APK.

## Initial APK files

Measured on disk before new builds. Build flags and provenance differ, so these are not a controlled size comparison:

| Existing file | Bytes |
| --- | ---: |
| `app-debug.apk` | 126,564,592 |
| `app-release.apk` | 59,970,144 |
| `app-arm64-v8a-release.apk` | 48,746,053 |
| `app-armeabi-v7a-release.apk` | 35,326,934 |
| `app-x86_64-release.apk` | 50,302,497 |

A fresh detached baseline worktree subsequently built with the exact command `flutter build apk --debug`: **199,835,661 bytes**, SHA-256 `efda476be131f2cd5cb11fad2681181021002adc938c57d86e394417d5a2950b`. This is the comparison baseline, rather than the pre-existing APK files above.

## Verified Android extractor options

| Candidate | Actual source/artifact findings | Decision |
| --- | --- | --- |
| `dev.ffmpegkit-maintained:yt-dlp-android:2.0.2` | Published AAR is 22,804,391 bytes; SHA-256 `d2e71858f4c144f021534e658b94d0c3616818b662c848903f1f2fe9dec4a7d0`. Chaquopy 17 / Python 3.13, Android API 24+, arm64-v8a and x86_64. Bundles yt-dlp 2026.06.09. Wrapper is MIT. | Retain as the Python runtime dependency; bypass its download wrapper. |
| `io.github.junkfood02.youtubedl-android:library:0.18.1` | Published AAR is 59,213,110 bytes, four ABIs, API 24+, Python 3.12.11 on arm64, QuickJS 2025-04-26, yt-dlp 2025.11.12 and EJS 0.3.1. `execute(request, processId, redirectErrorStream, callback)` exposes stdout and cancellation; JSON CLI extraction is viable. Wrapper is GPL-3.0. | Technically viable, but not adopted: older bundled extractor and a different wrapper license. No FFmpeg or aria2 dependency is needed for metadata resolution. |
| `io.github.deniscerri.youtubedl-android:library:0.19.0` | Published AAR is 59,127,824 bytes, four ABIs, API 24+, QuickJS-enabled wrapper, but bundled yt-dlp is 2025.09.26 without packaged EJS. Wrapper injects `--js-runtimes`; that upstream yt-dlp release predates the option. Current GitHub branch is not evidence about the published binary. GPL-3.0 wrapper. | Not adopted; published wrapper/runtime compatibility needs independent verification. |

The maintained 2.0.2 wrapper's `execute` returns empty stdout/stderr and its embedded bridge invokes `ydl.download([url])`. That public API is unsuitable here. Its `init(Context)` only starts Chaquopy through `AndroidPlatform`; it does not force an import of yt-dlp. The supported Chaquopy module/attribute bridge can instead call `YoutubeDL.extract_info(url, false)` and `sanitize_info` directly. No download is executed to obtain metadata.

The original AAR has Python JS providers and partial vendored EJS scripts, but no JavaScript executable, no full `yt_dlp_ejs` package, and no complete `yt.solver.lib.js` for QuickJS. This is a verified packaging gap, not proof that it caused every 403.

**Selected approach:** retain the existing Chaquopy adapter, load a pinned official yt-dlp **2026.08.19** Python zipimport bundle with matching **EJS 0.8.0**, and provide an Android QuickJS executable. No backend, automatic download of solver code, or replacement audio engine. Since direct on-device yt-dlp is technically viable, the conditional fallback to a different extraction engine is not required at this stage. Reliability remains subject to media playback tests.

Sources inspected:

- [2.0.2 Maven artifacts and Java source](https://repo.maven.apache.org/maven2/dev/ffmpegkit-maintained/yt-dlp-android/2.0.2/)
- [0.18.1 Maven artifacts and source](https://repo.maven.apache.org/maven2/io/github/junkfood02/youtubedl-android/library/0.18.1/)
- [0.19.0 Maven artifacts and source](https://repo.maven.apache.org/maven2/io/github/deniscerri/youtubedl-android/library/0.19.0/)
- [yt-dlp 2026.08.19](https://github.com/yt-dlp/yt-dlp/releases/tag/2026.08.19)
- [Pinned QuickJS provider implementation](https://github.com/yt-dlp/yt-dlp/blob/2026.08.19/yt_dlp/extractor/youtube/jsc/_builtin/quickjs.py)
- [Pinned EJS dependency](https://github.com/yt-dlp/yt-dlp/blob/2026.08.19/pyproject.toml)
- [EJS runtime requirements](https://github.com/yt-dlp/yt-dlp/wiki/EJS)
- [EJS 0.8.0 package](https://pypi.org/project/yt-dlp-ejs/0.8.0/)
- [Chaquopy Python API and module packaging](https://chaquo.com/chaquopy/doc/current/android.html)

## Integration and channel contract

`Flutter → com.example.harmoniq/yt_dlp → existing bounded native executor → YtDlpAdapter → Chaquopy Python → pinned yt-dlp + EJS + QuickJS → transient URL/headers → existing AudioService → just_audio`.

The adapter copies the bundled Python zip into the app's no-backup private runtime directory, prepends it to Python's module search path **before importing yt-dlp**, verifies yt-dlp/EJS versions, and checks that QuickJS can execute a simple arithmetic expression. QuickJS is packaged in Android's native-library directory, not executed from writable downloaded storage. Gradle enables extracted JNI packaging so Android installs the executable there. Unsupported runtime ABIs report unavailable rather than changing local playback.

| Method | Input | Output |
| --- | --- | --- |
| `isAvailable` | none | Whether the packaged QuickJS executable is available for this installed ABI; not a network/playability guarantee. |
| `initialize`, `getVersion` | none | Verified bundled yt-dlp version string. |
| `smoke` | none | Offline sanitized synthetic metadata and runtime version, without a media/network extraction. |
| `search` | `query` (nonblank, ≤200 characters), `limit` (1–10) | Metadata list: `id`, `title`, `artist`, `thumbnail`, `duration` in seconds, `sourceUrl`, `source`. |
| `resolve` | validated eleven-character `id` | Selected `id`, temporary `streamUrl`, `headers`, `format`, optional duration, canonical `sourceUrl`, `source`. |

### Search

Existing discovery retains its configured official YouTube Data API path when a key is present. Native no-key discovery uses a bounded `ytsearchN:` query with flat extraction. It returns metadata only, including a safe thumbnail from yt-dlp's thumbnails list when no singular thumbnail exists. It does not resolve every result, install audio, or persist temporary URLs. Pasted YouTube IDs/links retain the existing exact-host parser.

### Selected stream resolution

The adapter calls `extract_info(watchUrl, false)` with `simulate=true`, `skip_download=true`, `check_formats=false`, no disk extractor cache, no remote solver components, zero configured network/extractor/fragment retries, and a 12-second socket timeout. Format selection is `bestaudio[ext=m4a][protocol=https]/bestaudio[protocol=https]`. Returned selection must have no video codec, a nonempty audio codec, a supported audio extension, no advertised DRM, HTTPS protocol and a valid HTTPS URL without user-info. The existing safe transient User-Agent/Referer header contract remains; no invented cookies, credentials or header experiments.

Python objects are serialized using `sanitize_info` and `json.dumps`; extraction does not depend on parsing noisy stdout. yt-dlp's supported QuickJS provider captures the JavaScript process's stdout itself. Runtime files and short-lived JS scripts are not downloaded music.

### Expiration and stable persistence

Online `Song` persists stable metadata and the canonical watch URL derived from the video ID. Loading ignores untrusted/stale serialized source URLs and reconstructs that canonical URL; online `audioPath` remains empty. Stream URLs/headers remain local to a resolution and `AudioSource` installation.

Online source-load, play-future and active playback-event errors can trigger **one** automatic re-resolution of the same stable video ID. This includes 403 because expiration cannot reliably be distinguished from other refusals at that boundary. Position and paused/playing intent are retained; a second failure is surfaced. A resolver failure itself does not start an automatic loop. Manual retry is a new user-initiated attempt. Local failures never invoke the online resolver. Generation checks reject stale resolver/load/play completions during source changes.

### Limitations to retain in acceptance testing

- A complete JS/EJS installation is necessary for current challenge-solving paths but does not guarantee media delivery or bypass authentication, provider restrictions, geographic restrictions or rate limits.
- Dart's existing 20-second timeout does not cancel in-process Python extraction. The native executor still has one worker and four queued slots; socket timeout is not a total extraction deadline.
- The current Python AAR supports arm64-v8a and x86_64 only. A 32-bit APK must not be advertised as online-capable.
- The player emits untagged error events. Existing generation checks reject stale completion futures and transition-time events, but cannot attribute an untagged old event arriving after a new source is ready.
- Existing background notification/queue capabilities are preserved, not newly implemented. Custom playlists remain subject to their existing persistence behavior.
- No browser integration tools are available in this session. Flutter widget tests and physical Android interaction are the available substitutes; no UI layout or route files were changed.
- Production signing and a full transitive native/Python license audit remain separate release requirements.

## Automated results after Dart changes

`flutter analyze`: **no issues**. `flutter test --reporter expanded`: **129 passed**. Coverage includes local MediaStore URI behavior, all source-switch combinations through the shared queue, stable persistence, mocked search/home flows, fresh URL recovery, bounded 403 failures, paused recovery, duplicate errors and stale completions. These are not claims of network delivery or audible playback.

## Final Android build and size

`flutter build apk --debug` succeeded, and the resulting `build/app/outputs/flutter-apk/app-debug.apk` was installed on the authorized physical phone. The final APK is **111,686,095 bytes (106.512 MiB)**. Compared with the fresh baseline debug build of 199,835,661 bytes (190.578 MiB), this is **88,149,566 bytes (84.066 MiB) smaller**. This measures whole APKs, not the incremental cost of the extractor: native-library compression/packaging changed too. No equivalent final release/AAB size comparison was performed.

A final repeat `flutter analyze` reported no issues, `flutter test --reporter compact` passed all 129 tests, and `flutter build apk --debug` succeeded again. The repeat APK is byte-identical to the preceding installed-build artifact: SHA-256 `bd692793e20c9c2fb79d1985cbf7d1fda636c880f789aa7e0a8cb0b2bbeedf50`. The vendored runtime's offline verification and `git diff --check` also passed.

Inspection of the final APK verified that the Python zip, notices, and both native executables match the checked-in runtime bytes. Its manifest reports minimum API 24, target API 36 and `extractNativeLibs=true`. The arm64 phone logged `Runtime ready: yt-dlp 2026.08.19, EJS 0.8.0, QuickJS`. Runtime initialization and format resolution are not, on their own, playback acceptance.

## Physical-device acceptance results

Device: Motorola moto g45 5G, API 35, arm64-v8a. Local playback was checked before the controlled online checks. The user also independently exercised online playback during testing. Evidence below distinguishes UI/native state from the user's audible confirmation.

### Local playback on the installed APK

| Check | Observed result |
| --- | --- |
| MediaStore scan | 348 local songs appeared. |
| Select/play/pause/resume | Selected `Kaun Tujhe SlowedReverb Palak Muchhal Sloverb lyrics_320kbps`; position advanced to 0:23 and pause/resume worked. |
| Seek | While paused, moved from 0:23 to 2:53 of 4:25. |
| Background playback | Resumed, went Home, returned and paused at 3:14. |
| Next/local → local | Selected `METAMORPHOSIS (320 kbps)`, duration 2:22; playback position advanced. |
| Previous | First press reset 1:21 to 0:00; another selected the preceding Kaun Tujhe track. |
| Offline playback | Verified airplane mode enabled and `Active default network: none`; local playback advanced to 0:03. Connectivity was restored afterward. |
| Screen off/media control | With `mWakefulness=Dozing`, app media session reported PLAYING at position 7945 ms; media pause changed it to PAUSED at 9067 ms without an error. This is not a visual test of every lock-screen control. |
| Online → local | Switched from a paused Indila online track to the local Kaun Tujhe track successfully. |

These are device behavior observations, not an independent listening test by the agent. The initial attempt using `svc data disable` did not establish an offline state; only the later verified airplane-mode/no-network check is counted.

### Online playback and remaining failure evidence

The user explicitly confirmed audible playback of **three online tracks**: “ive plated 3 musics all those played well.” Their exact three titles were not all recorded. This is genuine physical-device playback confirmation, not inference from metadata or a READY state.

Observed search state included `love story by indila` with multiple correctly populated results. The full player showed `Indila - Love Story (Lyrics)` at **1:00 of 5:16**, paused, with seek enabled and the official music video queued next. A media pause command worked after the source was ready.

The new installed build also produced this retained, sanitized device-log sequence for public video **`24fdcMw0Bj0`**:

```text
YtDlpAdapter: Resolved 24fdcMw0Bj0, audio format 140
ExoPlayer: InvalidResponseCodeException: Response code: 403
YtDlpAdapter: Resolved 24fdcMw0Bj0, audio format 140
ExoPlayer: InvalidResponseCodeException: Response code: 403
```

This is a concise transcription of the observed messages, not a complete timestamped raw log. Signed stream URLs are deliberately excluded. It proves that the selected audio request was rejected even after another resolution. It does not establish whether the server rejected a signature, expired URL, client context, or another condition. A later third resolution occurred while the user was interacting with the phone; it cannot be attributed to an automatic retry loop from these observations. The automated tests separately verify the one-retry bound.

**Acceptance status: successful on-device playback is demonstrated, but reliable online playback is not yet established. The remaining 403 failures are unresolved.** No speculative headers, cookies, client impersonation, or additional automatic retry attempts were added in response.

### Incomplete physical checks

Controlled online seek/resume, next/previous, background playback, network-interruption recovery, and local → online / online → online transitions remain incompletely verified. The user’s three successful tracks do not substitute for an individually observed control/transition matrix. Screen-off playback and media pause were verified locally; every visual lock-screen control was not. Shuffle, repeat, favorites and playlists were not exhaustively exercised on-device; their implementations were preserved.

Device interaction stopped whenever Harmoniq was not foreground, and again at the final attempted continuation. Remaining device checks require the user to reopen/unlock Harmoniq and leave the phone available. No device pass is inferred from a Flutter mock test.

A pre-existing unrelated navigation issue was observed: the Home `Local Music` shortcut calls category index 3 (Favorites), while Local is index 5. Local scanning was accessed through Library instead. No UI change was made under this resolver-only scope.

## Files and dependencies changed

Relative to `checkpoint/player-before-resolver-20261007` (`97d446a`):

- `android/app/build.gradle.kts`: extracted native-library packaging.
- `android/app/src/main/kotlin/com/example/rachan/YtDlpAdapter.kt`: pinned runtime initialization, QuickJS selection, metadata extraction, audio-only selection and sanitized debug diagnostics.
- `android/app/src/main/assets/yt-dlp/`: pinned Python/EJS zip, third-party and NDK notices, `.gitattributes` preserving asset bytes.
- `android/app/src/main/jniLibs/{arm64-v8a,x86_64}/libharmoniq_quickjs.so`: source-built Android executables.
- `lib/services/audio_service.dart`: bounded online re-resolution across load/play/event failures; retained position and playback intent. This is an online recovery change inside the existing service, not a service rewrite.
- `lib/models/song.dart`, `lib/models/youtube_video.dart`: stable canonical source URLs and persistence checks.
- `test/native_youtube_audio_test.dart`, `test/yt_dlp_channel_test.dart`: recovery and stable-persistence regression coverage.
- `tools/vendor-ytdlp-runtime.ps1`: pinned fetch/build/verification recipe.
- This report, `docs/yt-dlp-migration-assessment.md`, and `docs/vendored-ytdlp-runtime.md`: evidence, historical status and provenance.

**Dependencies:** no pubspec/lockfile change, no replacement of just_audio, no Flutter version change, and no new Maven coordinate. The existing `dev.ffmpegkit-maintained:yt-dlp-android:2.0.2` remains the Python host. New vendored runtime components are yt-dlp 2026.08.19, EJS 0.8.0 and QuickJS 2025-04-26. Normal Flutter builds use these bundled files; rebuilding the vendored native assets requires the pinned NDK/host tools described in the provenance report, not Android Studio.

`MainActivity.kt`, `AndroidManifest.xml`, `lib/main.dart`, UI screens/widgets and Dart package files compare unchanged against the checkpoint. Local scanning/cleanup and local URI conversion were also compared against the checkpoint and are unchanged. Queue, player engine, favorites, playlists, shuffle/repeat and background/lock-screen architecture were not replaced.

The branch contains commit `ef79ca4` with the earlier recovery/model/tests work; the final native runtime and documentation additions remain working-tree changes. No push or additional final checkpoint commit was performed.

## Release limitations

- Remaining physical-device HTTP 403 failures prevent claiming a reliable online playback fix.
- Final physical online controls, network recovery and transition acceptance remain incomplete as listed above.
- arm64-v8a was exercised; x86_64 was statically validated but not run. The Python host does not support 32-bit Android, and API 24 is the minimum.
- Packaging/probing the EJS/QuickJS runtime does not prove that a particular extraction executed a live challenge solver. Future YouTube changes can still require a reviewed runtime update.
- In-process extraction has no cancellation at the Dart timeout; queued stale work can delay later requests. No new executor/player architecture was introduced.
- Production signing, release/AAB sizes, end-to-end 16-KB-page device testing and the full existing transitive license audit remain unverified. New component licenses/notices and reproducible-build limits are documented in [the runtime inventory](vendored-ytdlp-runtime.md).
- No backend was introduced: direct on-device extraction and playback are technically demonstrated, even though delivery reliability still needs work.
