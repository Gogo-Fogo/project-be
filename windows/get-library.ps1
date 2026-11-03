# Kiwix apps + the offline library into <data_dir>\Kiwix. Resumable: re-running continues and skips finished files.
#   -Tier small | medium | large   (default: library_tier in emergency.config.json; see docs/LIBRARY.md)
# Kiwix replaces old editions with newer dated ones: if a file 404s, look up the current name at
# https://download.kiwix.org/zim/ and update it here.
param([string]$Tier)
. "$PSScriptRoot\config.ps1"
if (-not $Tier) { $Tier = $Cfg.library_tier }
New-Item -ItemType Directory -Force $AppsDir, $LibDir | Out-Null

# download.kiwix.org itself can be very slow; these official mirrors are usually much faster. Tried in order.
$mirrors = @(
    'https://ftp.fau.de/kiwix',
    'https://mirror.accum.se/mirror/kiwix.org',
    'https://download.kiwix.org'
)
$wikipedia = @{
    small  = 'zim/wikipedia/wikipedia_en_all_mini_2026-09.zim'    # ~14 GB, article summaries
    medium = 'zim/wikipedia/wikipedia_en_all_nopic_2026-06.zim'   # ~53 GB, full text, no pictures
    large  = 'zim/wikipedia/wikipedia_en_all_maxi_2026-08.zim'    # ~127 GB, with pictures
}[$Tier]
if (-not $wikipedia) { throw "Unknown tier '$Tier' (small, medium or large)" }

$downloads = @(
    @{ path = 'release/kiwix-desktop/kiwix-desktop_windows_x64_2.5.1.zip'; dir = $AppsDir },  # reader app
    @{ path = 'release/kiwix-tools/kiwix-tools_win-x86_64-3.8.1.zip';      dir = $AppsDir },  # kiwix-serve for the AI
    # Smallest and most important first
    @{ path = 'zim/other/zimgit-medicine_en_2024-08.zim';           dir = $LibDir },
    @{ path = 'zim/wikivoyage/wikivoyage_en_all_nopic_2026-09.zim'; dir = $LibDir },
    @{ path = 'zim/other/zimgit-post-disaster_en_2024-05.zim';      dir = $LibDir },
    @{ path = 'zim/other/mdwiki_en_all_maxi_2025-11.zim';           dir = $LibDir },
    @{ path = 'zim/ifixit/ifixit_en_all_2025-12.zim';               dir = $LibDir },
    @{ path = $wikipedia;                                           dir = $LibDir }
)

foreach ($d in $downloads) {
    $name = Split-Path $d.path -Leaf
    $out  = Join-Path $d.dir $name
    Write-Output "=== $(Get-Date -Format HH:mm:ss) $name"
    $ok = $false
    foreach ($m in $mirrors) {
        # Abort a mirror that drops under 500 KB/s for 60 s, then try the next one
        curl.exe -L -C - --retry 3 --retry-delay 10 -s -S --speed-limit 512000 --speed-time 60 -o $out "$m/$($d.path)"
        if ($LASTEXITCODE -eq 0) { $ok = $true; break }
        Write-Output "    mirror $m failed ($LASTEXITCODE), trying next"
    }
    if (-not $ok) { Write-Output "!!! FAILED: $name" }
}

Get-ChildItem "$AppsDir\*.zip" | ForEach-Object {
    Expand-Archive $_.FullName -DestinationPath (Join-Path $AppsDir $_.BaseName) -Force
}
Write-Output "=== $(Get-Date -Format HH:mm:ss) done. Next: verify-library.ps1"
Get-ChildItem $LibDir | Select-Object Name, @{ n = 'GB'; e = { [math]::Round($_.Length / 1GB, 2) } }
