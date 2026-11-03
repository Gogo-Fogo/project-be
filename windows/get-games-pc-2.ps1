# More free, open-source games for the PC (round 2), official releases only, into <data_dir>\Games.
#   0 A.D.           Age of Empires-style strategy (heavier on the GPU; plug in to play long)
#   OpenRA           Red Alert / Command & Conquer remake, free and legal
#   fheroes2         Heroes of Might and Magic II engine + the free official demo (a few maps)
#   Blobby Volley 2  1v1 volleyball on one keyboard / two controllers
#   Armagetron       Tron light-cycles, up to 4 players split-screen
# Run once in PowerShell:  & .\windows\get-games-pc-2.ps1
. "$PSScriptRoot\config.ps1"
$root = $GamesDir
$dl   = Join-Path $root '_downloads'
New-Item -ItemType Directory -Force $root, $dl | Out-Null

$games = @(
    @{ name = 'OpenRA';          url = 'https://github.com/OpenRA/OpenRA/releases/download/release-20250330/OpenRA-release-20250330-x64-winportable.zip'; kind = 'zip' },
    @{ name = 'Heroes 2';        url = 'https://github.com/ihhub/fheroes2/releases/download/1.1.17/fheroes2_windows_x64_SDL2.zip'; kind = 'zip' },
    @{ name = 'Blobby Volley 2'; url = 'https://downloads.sourceforge.net/project/blobby/Blobby%20Volley%202%20%28Win32%29/1.1/blobby2-win32-1.1.zip'; kind = 'zip' },
    @{ name = 'Armagetron';      url = 'https://github.com/ArmagetronAd/armagetronad/releases/download/v0.2.9.3.1/armagetronad-0.2.9.3.1.win32.exe'; kind = 'nsis' },
    @{ name = '0 AD';            url = 'https://releases.wildfiregames.com/0ad-0.28.0-win64.exe'; kind = 'nsis' }
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

# Heroes 2 needs game data: fetch the free official demo now, while we have internet (checksum-verified by the script)
Push-Location (Join-Path $root 'Heroes 2')
powershell -ExecutionPolicy Bypass -File .\download_demo_version.ps1
Pop-Location

Write-Output "=== $(Get-Date -Format HH:mm:ss) done"
Write-Output "ONE MORE STEP while online: open OpenRA (Red Alert, Tiberian Dawn, Dune 2000) once each and click 'Quick Install' to fetch the free game files."
Get-ChildItem $root -Directory | Where-Object Name -ne '_downloads' | ForEach-Object {
    '{0,-22} {1,7:N0} MB' -f $_.Name, ((Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum / 1MB)
}
