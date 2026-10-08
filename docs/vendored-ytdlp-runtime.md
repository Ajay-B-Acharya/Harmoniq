# Vendored yt-dlp / EJS / QuickJS runtime

Recorded on 2026-10-07. This inventory covers the new runtime assets, native executables, and their build tooling. The existing MIT Chaquopy AAR dependency is retained; the integrated Kotlin adapter loads these assets as described in the [resolver integration and device report](youtube-resolver-2026-10-07.md). No GPL youtubedl-android wrapper, AAR, or prebuilt native component is incorporated.

## Packaged files

Paths are relative to the repository root. SHA-256 values identify the exact bytes, not just version labels.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| `android/app/src/main/assets/yt-dlp/yt-dlp.zip` | 3,072,469 | `1fa6733c37ea6fb51c99ad8fe785e7b7e5f3246c9b980230329d4fb72ed8d4d6` |
| `android/app/src/main/jniLibs/arm64-v8a/libharmoniq_quickjs.so` | 876,200 | `1490be6f9c07b63c4f00403e82c17fb0d45cda1430d91ab331a85a80b003191e` |
| `android/app/src/main/jniLibs/x86_64/libharmoniq_quickjs.so` | 929,368 | `392c93428ade35ef24af12f9f2242d2046bbca95efea4bed3ec03e30a9e0c076` |
| `android/app/src/main/assets/yt-dlp/NDK-TOOLCHAIN-NOTICE.txt` | 130,424 | `f96f763beb66a7ba7a667647fc64c0226ace875e590c831fdd9579ec1c1d91e1` |
| `android/app/src/main/assets/yt-dlp/THIRD-PARTY-NOTICES.txt` | 37,726 | `61d9293a76f00557c83daa9cec97148287ef7646c820d7971b28cb50ea430d26` |

`android/app/src/main/assets/yt-dlp/THIRD-PARTY-NOTICES.txt` contains the full project and embedded dependency notices described below. Both notice files are Android assets so they accompany the packaged runtime, rather than existing only in repository documentation. The adjacent `.gitattributes` disables Git text conversion for all three pinned asset files, preserving their exact hashes on Windows checkouts with `core.autocrlf=true`.

The `.so` suffix is for Android native packaging. These are **standalone PIE executables**, not JNI libraries; execute them by filesystem path, not `System.loadLibrary`.

## Official yt-dlp distribution and authentication limits

- Upstream Unix executable: <https://github.com/yt-dlp/yt-dlp/releases/download/2026.08.19/yt-dlp>.
- Official checksum manifest: <https://github.com/yt-dlp/yt-dlp/releases/download/2026.08.19/SHA2-256SUMS>.
- Manifest SHA-256: `a63701f30755cb4d9317950d69703e9d751d490cb1b7059e1bb501a353fe7dcb`.
- Its `yt-dlp` entry is `1fa6733c37ea6fb51c99ad8fe785e7b7e5f3246c9b980230329d4fb72ed8d4d6`, which matched the downloaded bytes before installation.

The Unix executable is a shebang-prefixed zipimport archive. It is copied byte-for-byte as `yt-dlp.zip`; it is not repacked, stripped, or replaced with a wheel. Its roots are `__main__.py`, `yt_dlp`, and `yt_dlp_ejs`. Inspection confirms yt-dlp **2026.08.19**, EJS **0.8.0**, and both `yt_dlp_ejs/yt/solver/core.min.js` (6,945 bytes) and `lib.min.js` (151,561 bytes). The latter includes the complete bundled parser/code-generator scripts and their license banner. Completeness here means the official distribution is preserved and those solver resources exist; it does not mean a live YouTube challenge was tested.

Downloads used official HTTPS endpoints. The release file and checksum manifest share an origin, so matching them is an integrity check, **not independent authentication** against a compromised upstream account. No release signature or external attestation was authenticated. The script pins both observed hashes and checks the exact manifest entry; it never resolves `latest`.

## Why the 0.18.1 prebuilt QuickJS components were not reused

The inspected `io.github.junkfood02.youtubedl-android:library:0.18.1` distribution contains `libqjs.so` binaries advertising QuickJS 2025-04-26. The wrapper project is GPL-3.0. The upstream introduction commit, [4e2bb8b4dbe15d13f57cf37c72e155b9f359d3fb](https://github.com/yausername/youtubedl-android/commit/4e2bb8b4dbe15d13f57cf37c72e155b9f359d3fb) ("Add quickJS", 2025-11-07), adds binaries and runtime integration but supplies no native build recipe or source-to-binary attestation. No corresponding recipe was found in the inspected tagged tree either.

A QuickJS version string alone cannot establish the exact linked source or license of those binaries. This is an unresolved provenance issue, not a claim that every separately distributed QuickJS executable is GPL. **None of those binaries were extracted into this app.** The fallback below builds the MIT engine from its official source archive instead.

## Exact QuickJS source and build proof

Source: <https://bellard.org/quickjs/quickjs-2025-04-26.tar.xz>, 579,376 bytes, SHA-256 `2f20074c25166ef6f781f381c50d57b502cb85d470d639abccebbef7954c83bf`.

This is an observed checksum pin of the official HTTPS download, not a separately signed upstream checksum. The archive supplies the MIT `LICENSE` and source-file copyright/permission headers. `LICENSE` is 1,130 bytes, SHA-256 `598fd7fc928e4350abce36e337ba5a1346923c5c692f5be92c3d8e29ddd7c18d`.

The exact target compilation units are `qjs.c`, generated `repl.c`, `quickjs.c`, `dtoa.c`, `libregexp.c`, `libunicode.c`, `cutils.c`, and `quickjs-libc.c`, using the archive's headers. No target source or header is patched. No GPL wrapper source, prebuilt object, library, or AAR is a build input.

| Input | SHA-256 |
| --- | --- |
| `qjs.c` | `388190f8aae3d0cc6ea30011e82b533aeb2df9a4f6fc7a35c26ec765f02fbd32` |
| `quickjs.c` | `1be1951aa05b034f2fc5fe0fb4b1aef64b4865e0788584c910f47010f6748162` |
| `dtoa.c` | `af5abd68fa9806d1a19bdd5f2daef00d5fd0990ae56311382dfed4700343f074` |
| `libregexp.c` | `880cf399d1e37705df7953e8c766e5e1b5585d9081a8caa9cc204045631eec4b` |
| `libunicode.c` | `97b0f708f89e3a5e9ffcd001340c20ed7809f2656443dc3262ae017769939c20` |
| `cutils.c` | `203cc40bb8c8f4e3c6ce81f50526c0605ec0c21428c3317422646b445bc2e8fb` |
| `quickjs-libc.c` | `a71131ea5adbf5634a70b1158e7719127421cd90450bcddd7e6d42cbc77c3ceb` |
| `repl.js` | `52d56daced27a76d14cd7ec8b2f5afeca3acd80772c29f7c3f06191620028404` |
| Generated `repl.c` | `f60d973ff6aec159b8a5fc4a337b5fa912e626f260062c662b07d524cd609a77` |
| Archive's `libunicode-table.h` | `cde1068e9aa6b985f4242dd9bafc39315b7e0faacf6eb92e76c700b24cb3e6a4` |

### Host bytecode generator

The installed host compiler is MinGW.org GCC-6.3.0-1 (GCC 6.3.0), normally `C:\MinGW\bin\gcc.exe`. It compiles a temporary `qjsc` from a separate copy of the upstream C/header files. Only that host copy disables `CONFIG_ATOMICS` and `USE_WORKER`, and renames local `setenv`/`unsetenv` functions and calls to avoid the old MinGW's declarations. Host flags include `-O0 -include malloc.h -fwrapv -D_GNU_SOURCE -D__USE_MINGW_ANSI_STDIO` and the explicit version/compiler/prefix definitions recorded in the script.

The host generator runs `-s -c -o repl.c -m repl.js`. Its sole shipped output is bytecode represented by the generated `repl.c` (86,666 bytes), whose hash is checked before cross-compilation. The Windows generator and GCC runtime are not shipped or linked into the Android executables. Android target sources retain upstream Atomics and Worker configuration.

### Android toolchain and flags

The installed toolchain is Android NDK **r28c / 28.2.13676358**, Windows x86-64, Clang **19.0.1**, Android build **13624864**, based on **r530567e**. `manifest_13624864.xml` records:

- LLVM/compiler-rt source: `toolchain/llvm-project` revision `97a699bf4812a18fb657c2779f5296a4ab2694d2`.
- Android toolchain build scripts: `toolchain/llvm_android` revision `e727bfb014bd436f581a66a450c939a6983a1fc3`.
- Bionic source: `platform/bionic` revision `b86008a9cd14a7748867d2232e6de439e4809c10`.

Tool identity pins:

| Installed toolchain input | SHA-256 |
| --- | --- |
| `bin/clang.exe` | `7d31c6f6fad98987b6c9d21b800afaa8b3e37f052e94aaddc941d42ff2a35579` |
| `bin/llvm-strip.exe` | `2d411db64e0b45508775e9e8fd436fb6e0af814a9dfbf8aea8fc37ce436c435c` |
| `manifest_13624864.xml` | `f6d04b56172c8d31f11cf7286208caa1dda259d544d72706ca56fc173ac1d47c` |
| Host `gcc.exe` | `a20b2286ddee05f01aa5d8f0933826c4cc3dfd04f28aae7d04901565cb5783cb` |

These identify the installed tools used, not an independently authenticated NDK download or a source rebuild of GCC/LLVM/Bionic. NDK prebuilt startup/runtime objects are trusted toolchain inputs; output hashes also fail closed if other toolchain inputs change the result.

Target triples are `aarch64-linux-android24` and `x86_64-linux-android24`. Both builds use `-O2 -fwrapv -funsigned-char -fPIE -ffunction-sections -fdata-sections -D_GNU_SOURCE`, `CONFIG_VERSION="2025-04-26"`, and the eight compilation units above. Link flags are `-pie -Wl,--gc-sections -Wl,--build-id=sha1 -Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384 -Wl,-Map,<abi>.map -lm -ldl`. `llvm-strip --strip-all` produces the packaged bytes. Response files preserve C string quoting under Windows PowerShell; the checked-in script is the executable recipe.

Static ELF inspection shows both are little-endian ELF64 DYN/PIE, with the correct AArch64/x86-64 machine, interpreter `/system/bin/linker64`, all LOAD segment alignments `0x4000`, and `NOW PIE` flags. Their only `DT_NEEDED` entries are Android `libm.so`, `libdl.so`, and `libc.so`. Those system libraries are not bundled.

Link maps also show NDK startup objects and, for arm64, statically incorporated compiler-rt builtins including `udivti3.c.o`, `udivmodti4.c.o`, `aarch64.c.o`, and outline atomic assembly objects. Therefore **MIT describes QuickJS, not every byte of the final executable**. Bionic CRT and LLVM runtime notices also apply. Absence of a GPL dependency is supported by the controlled source/command inputs and link maps, not inferred merely from the three dynamic dependency names.

## License inventory and notice sources

| Component | License / preserved attribution |
| --- | --- |
| yt-dlp 2026.08.19 | Unlicense; full version-tagged upstream license. |
| yt-dlp-ejs 0.8.0 | Unlicense; full version-tagged upstream license. |
| EJS bundled meriyah 6.1.4 | ISC; Copyright 2019 and later, KFlash and others; full verbatim bundle notice. |
| EJS bundled astring 1.9.0 | MIT; Copyright 2015 David Bonnet; full verbatim bundle notice. |
| QuickJS 2025-04-26 | MIT; Fabrice Bellard and Charlie Gordon. Full archive LICENSE plus individual target source/header and `repl.js` notice blocks, preserving differing years/authorship. |
| QuickJS compressed Unicode data | Unicode License V3 included conservatively; archive `unicode_download.sh` identifies Unicode 16.0.0. |
| NDK Bionic CRT | BSD-2-Clause; Android Open Source Project, 2012 (`crtbegin.c`) and 2008 (`crtend.S`). Full source headers preserved. |
| NDK compiler-rt / LLVM runtime | Apache-2.0 WITH LLVM-exception and upstream runtime notices; the installed toolchain's complete NOTICE is copied unchanged as `NDK-TOOLCHAIN-NOTICE.txt`. This broad notice contains additional components not necessarily linked into these executables. |

Pinned fetched notice inputs:

- <https://raw.githubusercontent.com/yt-dlp/yt-dlp/2026.08.19/LICENSE>: SHA-256 `7e12e5df4bae12cb21581ba157ced20e1986a0508dd10d0e8a4ab9a4cf94e85c`.
- <https://raw.githubusercontent.com/yt-dlp/ejs/0.8.0/LICENSE>: SHA-256 `b5065838cbac452dfc855ba6e6e031481ad2c68406f70d21ead9321374653e6c`.
- <https://www.unicode.org/license.txt>: SHA-256 `e7a93b009565cfce55919a381437ac4db883e9da2126fa28b91d12732bc53d96`, official Unicode License V3 snapshot with Copyright 1991-2026, fetched on 2026-10-07. This URL is not versioned; its bytes are pinned, and a future upstream change causes a hard failure, not a silent notice update.
- [Bionic crtbegin.c](https://android.googlesource.com/platform/bionic/+/b86008a9cd14a7748867d2232e6de439e4809c10/libc/arch-common/bionic/crtbegin.c?format=TEXT): decoded source SHA-256 `25e4e95c97e263fb402ee73774598a0f9886babe4f5cbbb0530aa7d888fd5d2d`.
- [Bionic crtend.S](https://android.googlesource.com/platform/bionic/+/b86008a9cd14a7748867d2232e6de439e4809c10/libc/arch-common/bionic/crtend.S?format=TEXT): decoded source SHA-256 `67447574b30707d446aeeb6f5ef5836b00921271921f2fc68e4793d40eb3c700`.

Unicode provenance limit: `libunicode-table.h` is used unchanged from the pinned QuickJS archive. The archive's `unicode_download.sh` names the Unicode 16.0.0 UCD; the official [16.0.0 ReadMe](https://www.unicode.org/Public/16.0.0/ucd/ReadMe.txt) confirms that dataset version. The table generator is upstream MIT code. The Unicode tables were **not independently regenerated or compared to the raw UCD** in this task. The Unicode notice is retained rather than assuming generated data has no notice requirements.

The Bionic revision above is the installed NDK manifest's recorded source revision. Fetching its copyright headers does not independently prove how Google's prebuilt CRT objects were compiled. No claim of a fully bootstrapped or independently attested toolchain is made.

## Reproduction and verification

Run from the repository root in Windows PowerShell 5.1 or later. The tested setup uses Python 3.13, Windows `tar.exe`, the installed NDK r28c, and the MinGW host compiler identified above. The script does not install or upgrade prerequisites.

- Offline checksum and static content verification: `& .\tools\vendor-ytdlp-runtime.ps1 -VerifyOnly -PythonExe "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe"`.
- Fetch, verify, rebuild and install: `& .\tools\vendor-ytdlp-runtime.ps1 -PythonExe "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe" -KeepWorkDirectory`.
- Use `-NdkPath` or `-HostGcc` for alternative installation paths containing the same pinned tools. `-PythonExe` accepts a Python executable path, not a command plus arguments.

Build mode creates a fresh temporary directory, downloads only pinned upstream runtime/source/license material, validates hashes before use, checks the official yt-dlp checksum entry, generates the host bytecode, cross-compiles and strips both executables, checks their exact output hashes, and generates notices. All downloads and native build hashes must pass before installation begins. Existing destination files must already match; mismatches are not silently overwritten. Installation is not an atomic multi-file transaction. `-KeepWorkDirectory` prints the directory containing source inputs, response files and link maps for audit; otherwise it is removed.

Independent fresh-directory builds reproduced both native hashes and the final notice hash. The final fetch/build/install run and offline verification both passed. The offline verifier checks packaged hashes, Python/EJS versions and solver resources, ELF machines, PIE flags, interpreter, 16-KB LOAD alignment, and dynamic dependencies. A separate audit verified every ZIP entry's CRC, all 45 upstream C/header/JS source files against the archive, documented input hashes, and preservation of the complete license texts. Isolated one-byte corruption tests confirmed rejection of an altered zip, native executable, and third-party notice. These checks inspect bytes; they do not execute the packaged engine or extract media.

### Integration boundaries and unverified behavior

The integrated application enables extracted native-library packaging in Gradle. `YtDlpAdapter.kt` prioritizes the official Python zip over the older AAR's package, validates the bundled yt-dlp/EJS versions, and selects the packaged QuickJS executable. These executables are launched by path, not loaded as JNI libraries or executed directly inside an APK.

The [resolver integration and device report](youtube-resolver-2026-10-07.md) records the successful debug APK build/install, matching packaged asset bytes, on-device runtime initialization, successful playback reported by the user, and remaining HTTP 403 failures. Those integration results are distinct from this inventory's static verification and reproducible-build checks. They do not establish that a live JavaScript challenge was invoked and solved on every tested extraction.

16-KB ELF alignment is verified, not end-to-end Android page-size compatibility. Metadata extraction does not download media; subsequent player streaming necessarily transfers audio. Existing Chaquopy/AAR and whole-application license obligations remain outside this inventory.
