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
