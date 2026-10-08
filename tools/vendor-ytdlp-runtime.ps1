[CmdletBinding()]
param(
    [switch]$VerifyOnly,
    [string]$NdkPath = "$env:LOCALAPPDATA\Android\sdk\ndk\28.2.13676358",
    [string]$HostGcc = 'C:\MinGW\bin\gcc.exe',
    [string]$PythonExe = 'python',
    [switch]$KeepWorkDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = Split-Path -Parent $PSScriptRoot
$main = Join-Path $root 'android\app\src\main'
$utf8 = [Text.UTF8Encoding]::new($false)
$ytHash = '1fa6733c37ea6fb51c99ad8fe785e7b7e5f3246c9b980230329d4fb72ed8d4d6'
$sourceHash = '2f20074c25166ef6f781f381c50d57b502cb85d470d639abccebbef7954c83bf'
$replHash = 'f60d973ff6aec159b8a5fc4a337b5fa912e626f260062c662b07d524cd609a77'
$ndkNoticeHash = 'f96f763beb66a7ba7a667647fc64c0226ace875e590c831fdd9579ec1c1d91e1'
$noticeHash = '61d9293a76f00557c83daa9cec97148287ef7646c820d7971b28cb50ea430d26'
$targets = @(
    @{ Abi = 'arm64-v8a'; Triple = 'aarch64-linux-android24'; Hash = '1490be6f9c07b63c4f00403e82c17fb0d45cda1430d91ab331a85a80b003191e' },
    @{ Abi = 'x86_64'; Triple = 'x86_64-linux-android24'; Hash = '392c93428ade35ef24af12f9f2242d2046bbca95efea4bed3ec03e30a9e0c076' }
)

function Assert-Hash([string]$Path, [string]$Expected) {
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $Expected) { throw "SHA-256 mismatch for $Path : $actual" }
}

function Invoke-Checked([string]$Executable, [string[]]$Arguments) {
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Executable failed with exit code $LASTEXITCODE" }
}

function Install-Verified([string]$Source, [string]$Destination, [string]$Expected) {
    Assert-Hash $Source $Expected
    if (Test-Path -LiteralPath $Destination) {
        Assert-Hash $Destination $Expected
        return
    }
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Destination)) | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Destination
    Assert-Hash $Destination $Expected
}

function Test-PackagedRuntime {
    Assert-Hash (Join-Path $main 'assets\yt-dlp\yt-dlp.zip') $ytHash
    Assert-Hash (Join-Path $main 'assets\yt-dlp\NDK-TOOLCHAIN-NOTICE.txt') $ndkNoticeHash
    Assert-Hash (Join-Path $main 'assets\yt-dlp\THIRD-PARTY-NOTICES.txt') $noticeHash
    foreach ($target in $targets) {
        Assert-Hash (Join-Path $main "jniLibs\$($target.Abi)\libharmoniq_quickjs.so") $target.Hash
    }
    $check = @'
import pathlib, struct, sys, zipfile
root = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(root / 'assets/yt-dlp/yt-dlp.zip') as z:
    assert "__version__ = '2026.08.19'" in z.read('yt_dlp/version.py').decode()
    assert "version = '0.8.0'" in z.read('yt_dlp_ejs/_version.py').decode()
    for name in ['core.min.js', 'lib.min.js']:
        assert len(z.read('yt_dlp_ejs/yt/solver/' + name)) > 1000
    assert {n.split('/')[0] for n in z.namelist()} == {'__main__.py', 'yt_dlp', 'yt_dlp_ejs'}
for abi, machine in [('arm64-v8a', 183), ('x86_64', 62)]:
    b = (root / 'jniLibs' / abi / 'libharmoniq_quickjs.so').read_bytes()
    assert b[:6] == b'\x7fELF\x02\x01'
    assert struct.unpack_from('<HH', b, 16) == (3, machine)
    off = struct.unpack_from('<Q', b, 32)[0]
    stride, count = struct.unpack_from('<HH', b, 54)
    headers = [struct.unpack_from('<IIQQQQQQ', b, off + i * stride) for i in range(count)]
    loads = [h for h in headers if h[0] == 1]
    assert loads and all(h[7] == 16384 for h in loads)
    interp = next(h for h in headers if h[0] == 3)
    assert b[interp[2]:interp[2]+interp[5]].rstrip(b'\0') == b'/system/bin/linker64'
    dynamic = next(h for h in headers if h[0] == 2)
    tags = [struct.unpack_from('<qQ', b, p) for p in range(dynamic[2], dynamic[2]+dynamic[5], 16)]
    address = next(v for t, v in tags if t == 5)
    load = next(h for h in loads if h[3] <= address < h[3]+h[5])
    strings = load[2] + address - load[3]
    needed = {b[strings+v:].split(b'\0', 1)[0].decode() for t, v in tags if t == 1}
    assert needed == {'libc.so', 'libm.so', 'libdl.so'}, needed
    assert any(t == 0x6ffffffb and v & 0x08000000 for t, v in tags)
    assert b'QuickJS version 2025-04-26' in b
    print(abi + ': API-24 build, ELF64 PIE, 16-KB LOAD alignment, Android system dependencies only')
print('Verified pinned yt-dlp 2026.08.19, complete EJS 0.8.0, and both QuickJS executables; no code executed.')
'@
    $check | & $PythonExe -B - $main
    if ($LASTEXITCODE -ne 0) { throw 'Packaged runtime inspection failed' }
}

if ($VerifyOnly) {
    Test-PackagedRuntime
    return
}

$ndk = (Resolve-Path -LiteralPath $NdkPath).Path
$toolchain = Join-Path $ndk 'toolchains\llvm\prebuilt\windows-x86_64'
$bin = Join-Path $toolchain 'bin'
if ([IO.File]::ReadAllText((Join-Path $ndk 'source.properties')) -notmatch '(?m)^Pkg.Revision = 28\.2\.13676358\r?$') {
    throw 'The pinned build requires Android NDK 28.2.13676358 (r28c)'
}
Assert-Hash (Join-Path $toolchain 'NOTICE') $ndkNoticeHash
Assert-Hash (Join-Path $toolchain 'manifest_13624864.xml') 'f6d04b56172c8d31f11cf7286208caa1dda259d544d72706ca56fc173ac1d47c'
Assert-Hash (Join-Path $bin 'clang.exe') '7d31c6f6fad98987b6c9d21b800afaa8b3e37f052e94aaddc941d42ff2a35579'
Assert-Hash (Join-Path $bin 'llvm-strip.exe') '2d411db64e0b45508775e9e8fd436fb6e0af814a9dfbf8aea8fc37ce436c435c'
Assert-Hash $HostGcc 'a20b2286ddee05f01aa5d8f0933826c4cc3dfd04f28aae7d04901565cb5783cb'
$gccVersion = (& $HostGcc --version | Out-String)
if ($LASTEXITCODE -ne 0 -or $gccVersion -notmatch 'MinGW.org GCC-6\.3\.0-1') {
    throw 'The verified host generator uses MinGW.org GCC-6.3.0-1; other hosts require an explicit reproducibility review'
}
$clangVersion = (& (Join-Path $bin 'clang.exe') --version | Out-String)
if ($LASTEXITCODE -ne 0 -or $clangVersion -notmatch '97a699bf4812a18fb657c2779f5296a4ab2694d2') {
    throw 'Unexpected Android clang revision'
}

Add-Type -AssemblyName System.Net.Http
$http = [Net.Http.HttpClient]::new()
$http.Timeout = [TimeSpan]::FromMinutes(3)
$work = Join-Path ([IO.Path]::GetTempPath()) ('harmoniq-runtime-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($work) | Out-Null

function Get-Verified([string]$Url, [string]$Name, [string]$Expected, [switch]$Base64) {
    $bytes = $http.GetByteArrayAsync($Url).GetAwaiter().GetResult()
    if ($Base64) { $bytes = [Convert]::FromBase64String([Text.Encoding]::UTF8.GetString($bytes)) }
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $actual = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    if ($actual -ne $Expected) { throw "Downloaded checksum mismatch: $Url : $actual" }
    $path = Join-Path $work $Name
    [IO.File]::WriteAllBytes($path, $bytes)
    return $path
}

try {
    $release = 'https://github.com/yt-dlp/yt-dlp/releases/download/2026.08.19'
    $sums = Get-Verified "$release/SHA2-256SUMS" 'SHA2-256SUMS' 'a63701f30755cb4d9317950d69703e9d751d490cb1b7059e1bb501a353fe7dcb'
    if (-not [regex]::IsMatch([IO.File]::ReadAllText($sums), "(?m)^$ytHash  yt-dlp\r?$")) {
        throw 'Official checksum manifest does not contain the pinned Unix executable'
    }
    $yt = Get-Verified "$release/yt-dlp" 'yt-dlp' $ytHash
    $archive = Get-Verified 'https://bellard.org/quickjs/quickjs-2025-04-26.tar.xz' 'quickjs.tar.xz' $sourceHash
    $null = Get-Verified 'https://raw.githubusercontent.com/yt-dlp/yt-dlp/2026.08.19/LICENSE' 'YT-DLP-LICENSE' '7e12e5df4bae12cb21581ba157ced20e1986a0508dd10d0e8a4ab9a4cf94e85c'
    $null = Get-Verified 'https://raw.githubusercontent.com/yt-dlp/ejs/0.8.0/LICENSE' 'EJS-LICENSE' 'b5065838cbac452dfc855ba6e6e031481ad2c68406f70d21ead9321374653e6c'
    $null = Get-Verified 'https://www.unicode.org/license.txt' 'UNICODE-LICENSE' 'e7a93b009565cfce55919a381437ac4db883e9da2126fa28b91d12732bc53d96'
    $bionic = 'https://android.googlesource.com/platform/bionic/+/b86008a9cd14a7748867d2232e6de439e4809c10/libc/arch-common/bionic'
    $null = Get-Verified "$bionic/crtbegin.c?format=TEXT" 'crtbegin.c' '25e4e95c97e263fb402ee73774598a0f9886babe4f5cbbb0530aa7d888fd5d2d' -Base64
    $null = Get-Verified "$bionic/crtend.S?format=TEXT" 'crtend.S' '67447574b30707d446aeeb6f5ef5836b00921271921f2fc68e4793d40eb3c700' -Base64
    Invoke-Checked 'tar.exe' @('-xf', $archive, '-C', $work)
    $src = Join-Path $work 'quickjs-2025-04-26'
    $hostDir = Join-Path $src 'host'
    [IO.Directory]::CreateDirectory($hostDir) | Out-Null
    Get-ChildItem -LiteralPath $src -File | Where-Object { $_.Extension -in @('.c', '.h') } | Copy-Item -Destination $hostDir

    # These compatibility changes affect only the temporary Windows bytecode generator.
    $hostCore = Join-Path $hostDir 'quickjs.c'
    $text = [IO.File]::ReadAllText($hostCore)
    if (($text.Split(@('#define CONFIG_ATOMICS'), [StringSplitOptions]::None)).Count -ne 2) { throw 'Unexpected host core source' }
    [IO.File]::WriteAllText($hostCore, $text.Replace('#define CONFIG_ATOMICS', '#undef CONFIG_ATOMICS'), $utf8)
    $hostLibc = Join-Path $hostDir 'quickjs-libc.c'
    $text = [IO.File]::ReadAllText($hostLibc)
    if (($text.Split(@('#define USE_WORKER'), [StringSplitOptions]::None)).Count -ne 2) { throw 'Unexpected host libc source' }
    $text = $text.Replace('#define USE_WORKER', '#undef USE_WORKER').Replace(' setenv(', ' qjs_host_setenv(').Replace(' unsetenv(', ' qjs_host_unsetenv(')
    [IO.File]::WriteAllText($hostLibc, $text, $utf8)
    # Response files preserve C string quotes in Windows PowerShell 5.1.
    $hostArgs = @'
-O0
-include
malloc.h
-fwrapv
-D_GNU_SOURCE
-D__USE_MINGW_ANSI_STDIO
-DCONFIG_VERSION=\"2025-04-26\"
-DCONFIG_CC=\"gcc\"
-DCONFIG_PREFIX=\".\"
qjsc.c
quickjs.c
dtoa.c
libregexp.c
libunicode.c
cutils.c
quickjs-libc.c
-lm
-o
host-qjsc.exe
'@
    [IO.File]::WriteAllText((Join-Path $hostDir 'host-build.rsp'), $hostArgs, $utf8)
    Push-Location $hostDir
    try { Invoke-Checked $HostGcc @('@host-build.rsp') }
    finally { Pop-Location }
    Push-Location $src
    try {
        Invoke-Checked (Join-Path $hostDir 'host-qjsc.exe') @('-s', '-c', '-o', 'repl.c', '-m', 'repl.js')
        Assert-Hash (Join-Path $src 'repl.c') $replHash
        foreach ($target in $targets) {
            $abi = $target.Abi
            $targetArgs = @"
--target=$($target.Triple)
-O2
-fwrapv
-funsigned-char
-fPIE
-ffunction-sections
-fdata-sections
-D_GNU_SOURCE
-DCONFIG_VERSION=\"2025-04-26\"
qjs.c
repl.c
quickjs.c
dtoa.c
libregexp.c
libunicode.c
cutils.c
quickjs-libc.c
-pie
-Wl,--gc-sections
-Wl,--build-id=sha1
-Wl,-z,max-page-size=16384
-Wl,-z,common-page-size=16384
-Wl,-Map,$abi.map
-lm
-ldl
-o
$abi-qjs
"@
            [IO.File]::WriteAllText((Join-Path $src "$abi.rsp"), $targetArgs, $utf8)
            Invoke-Checked (Join-Path $bin 'clang.exe') @("@$abi.rsp")
            Invoke-Checked (Join-Path $bin 'llvm-strip.exe') @('--strip-all', "$abi-qjs")
            Assert-Hash (Join-Path $src "$abi-qjs") $target.Hash
            Invoke-Checked (Join-Path $bin 'llvm-readelf.exe') @('--dynamic', "$abi-qjs")
        }
    } finally { Pop-Location }

    $notices = @'
import pathlib, sys, zipfile
work = pathlib.Path(sys.argv[1])
src = work / 'quickjs-2025-04-26'
parts = ['HARMONIQ VENDORED YT-DLP / EJS / QUICKJS NOTICES\n\n'
         'These notices cover the newly vendored runtime files, not the existing Chaquopy AAR or the whole application.\n'
         'See docs/vendored-ytdlp-runtime.md and tools/vendor-ytdlp-runtime.ps1 for pinned sources, hashes and build details.\n'
         'No youtubedl-android wrapper or prebuilt qjs binary from that project is included.\n'
         'NDK compiler runtime notices are reproduced separately in NDK-TOOLCHAIN-NOTICE.txt.']
for title, name in [('yt-dlp 2026.08.19 - Unlicense', 'YT-DLP-LICENSE'), ('yt-dlp-ejs 0.8.0 - Unlicense', 'EJS-LICENSE')]:
    parts.extend([title, (work / name).read_text(encoding='utf-8')])
with zipfile.ZipFile(work / 'yt-dlp') as z:
    banner = z.read('yt_dlp_ejs/yt/solver/lib.min.js').decode('utf-8').split('*/', 1)[0] + '*/'
parts.extend(['EJS bundled meriyah 6.1.4 (ISC) and astring 1.9.0 (MIT): verbatim distribution banner', banner])
parts.extend(['QuickJS 2025-04-26 - MIT: upstream LICENSE', (src / 'LICENSE').read_text(encoding='utf-8')])
files = ['qjs.c', 'quickjs.c', 'dtoa.c', 'libregexp.c', 'libunicode.c', 'cutils.c', 'quickjs-libc.c', 'repl.js',
         'cutils.h', 'dtoa.h', 'libregexp.h', 'libregexp-opcode.h', 'libunicode.h', 'list.h',
         'quickjs.h', 'quickjs-libc.h', 'quickjs-atom.h', 'quickjs-opcode.h']
for name in files:
    text = (src / name).read_text(encoding='utf-8')
    assert text.startswith('/*'), name
    parts.extend(['QuickJS source notice: ' + name, text.split('*/', 1)[0] + '*/'])
parts.extend(['Unicode data notice (Unicode License V3)\n'
              'QuickJS ships compressed Unicode tables; its unicode_download.sh identifies Unicode 16.0.0.\n'
              'The tables are used unchanged from the pinned QuickJS archive, not regenerated here.\n'
              'The following official license.txt snapshot was fetched on 2026-10-07 and is checksum-pinned.',
              (work / 'UNICODE-LICENSE').read_text(encoding='utf-8')])
for name in ['crtbegin.c', 'crtend.S']:
    text = (work / name).read_text(encoding='utf-8')
    parts.extend(['Android Bionic CRT (BSD-2-Clause): ' + name + '\nSource revision: b86008a9cd14a7748867d2232e6de439e4809c10', text.split('*/', 1)[0] + '*/'])
(work / 'THIRD-PARTY-NOTICES.txt').write_bytes(('\n\n' + ('\n\n' + '=' * 78 + '\n\n').join(parts) + '\n').encode('utf-8'))
'@
    $notices | & $PythonExe -B - $work
    if ($LASTEXITCODE -ne 0) { throw 'Notice generation failed' }
    $noticePath = Join-Path $work 'THIRD-PARTY-NOTICES.txt'
    Assert-Hash $noticePath $noticeHash

    # Nothing is installed until all downloads and both native build hashes pass.
    Install-Verified $yt (Join-Path $main 'assets\yt-dlp\yt-dlp.zip') $ytHash
    foreach ($target in $targets) {
        Install-Verified (Join-Path $src "$($target.Abi)-qjs") (Join-Path $main "jniLibs\$($target.Abi)\libharmoniq_quickjs.so") $target.Hash
    }
    Install-Verified $noticePath (Join-Path $main 'assets\yt-dlp\THIRD-PARTY-NOTICES.txt') $noticeHash
    Install-Verified (Join-Path $toolchain 'NOTICE') (Join-Path $main 'assets\yt-dlp\NDK-TOOLCHAIN-NOTICE.txt') $ndkNoticeHash
    Test-PackagedRuntime
    Write-Output "Third-party notice SHA-256: $noticeHash"
} finally {
    $http.Dispose()
    if ($KeepWorkDirectory) { Write-Output "Build sources, response files and link maps: $work" }
    else { Remove-Item -LiteralPath $work -Recurse -Force }
}
