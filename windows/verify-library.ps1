# Verify every ZIM in the library against Kiwix's published SHA-256 (download.kiwix.org).
# Read-only; takes ~10 min per ~70 GB.
. "$PSScriptRoot\config.ps1"
$lib = $LibDir
$folders = @{ wikipedia = 'wikipedia'; wikivoyage = 'wikivoyage'; ifixit = 'ifixit' }

Get-ChildItem "$lib\*.zim" | Sort-Object Length | ForEach-Object {
    $prefix = ($_.Name -split '_')[0]
    $folder = if ($folders.ContainsKey($prefix)) { $folders[$prefix] } else { 'other' }
    $want = ((curl.exe -sL -m 60 "https://download.kiwix.org/zim/$folder/$($_.Name).sha256") -split '\s+')[0]
    $got  = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    $status = if ($want -notmatch '^[0-9a-f]{64}$') { 'NO CHECKSUM' } elseif ($got -eq $want) { 'OK' } else { 'MISMATCH' }
    Write-Output ("{0,-42} {1}" -f $_.Name, $status)
}
