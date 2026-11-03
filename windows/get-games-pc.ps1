# Free, open-source, offline games for the PC into <data_dir>\Games (official releases only).
# Portable zips where the project offers them; Wesnoth and Hedgewars use their silent installers.
. "$PSScriptRoot\config.ps1"
$root = $GamesDir
$dl   = Join-Path $root '_downloads'
New-Item -ItemType Directory -Force $root, $dl | Out-Null

$games = @(
    @{ name = 'Pixel Wheels';      url = 'https://github.com/agateau/pixelwheels/releases/download/1.0.1/pixelwheels-1.0.1-windows64.zip'; kind = 'zip' },
    @{ name = 'SuperTux';          url = 'https://github.com/SuperTux/supertux/releases/download/v0.7.0/SuperTux-v0.7.0-win64-portable.zip'; kind = 'zip' },
    @{ name = 'Dungeon Crawl';     url = 'https://github.com/crawl/crawl/releases/download/0.34.1/dcss-0.34.1-win32-tiles.zip'; kind = 'zip' },
    @{ name = 'OpenTTD';           url = 'https://cdn.openttd.org/openttd-releases/15.3/openttd-15.3-windows-win64.zip'; kind = 'zip' },
    @{ name = 'OpenTTD\baseset';   url = 'https://cdn.openttd.org/opengfx-releases/8.0/opengfx-8.0-all.zip'; kind = 'zip' },  # free graphics; OpenTTD can't download them offline
    @{ name = 'SuperTuxKart';      url = 'https://github.com/supertuxkart/stk-code/releases/download/1.5/SuperTuxKart-1.5-win.zip'; kind = 'zip' },
    @{ name = 'Battle for Wesnoth'; url = 'https://downloads.sourceforge.net/project/wesnoth/wesnoth-1.18/wesnoth-1.18.8/wesnoth-1.18.8-win64.exe'; kind = 'nsis' },
    @{ name = 'Hedgewars';         url = 'https://www.hedgewars.org/download/releases/Hedgewars-1.0.0.exe'; kind = 'nsis' }
)

foreach ($g in $games) {
    $file = Join-Path $dl (Split-Path ($g.url -replace '\?.*$', '') -Leaf)
    $dest = Join-Path $root $g.name
    Write-Output "=== $(Get-Date -Format HH:mm:ss) $($g.name)"
    curl.exe -L -C - --retry 3 -s -S -o $file $g.url
    if ($LASTEXITCODE -ne 0) { Write-Output "!!! download failed: $($g.name)"; continue }
    if ($g.kind -eq 'zip') {
        Expand-Archive $file -DestinationPath $dest -Force
    } else {
        # NSIS installers: /S = silent, /D = install folder (must be last, unquoted)
        Start-Process $file -ArgumentList '/S', "/D=$dest" -Wait
    }
    Write-Output "    -> $dest"
}
# OpenGFX ships as a .tar inside the zip; OpenTTD reads the .tar from its baseset folder as is
Get-ChildItem "$root\OpenTTD" -Recurse -Filter 'openttd.exe' | Select-Object -First 1 | ForEach-Object { Write-Output "OpenTTD: $($_.FullName)" }
Write-Output "=== $(Get-Date -Format HH:mm:ss) done"
Get-ChildItem $root -Directory | Where-Object Name -ne '_downloads' | ForEach-Object {
    '{0,-22} {1,7:N0} MB' -f $_.Name, ((Get-ChildItem $_.FullName -Recurse -File | Measure-Object Length -Sum).Sum / 1MB)
}
