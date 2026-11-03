# Start the offline library + local AI, then open the Emergency Help chat page
# (tools/chat_server.py) in the browser. -Terminal asks in this window instead (tools/ask.py).
# Safety limits: VRAM kept free for the screen, one model at a time, 2 min load timeout.
param([string]$Model, [switch]$NoBrowser, [switch]$Terminal)
. "$PSScriptRoot\config.ps1"
if (-not $Model) { $Model = $Cfg.model }

if ($Cfg.ollama_models) { $env:OLLAMA_MODELS = $Cfg.ollama_models }
$env:OLLAMA_GPU_OVERHEAD      = [string]([int64]$Cfg.gpu_overhead_gb * 1GB)
$env:OLLAMA_MAX_LOADED_MODELS = '1'
$env:OLLAMA_LOAD_TIMEOUT      = '2m'

$ollama = (Get-Command ollama -ErrorAction SilentlyContinue).Source
if (-not $ollama) { $ollama = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe" }
$kiwix  = Get-ChildItem $AppsDir -Recurse -Filter kiwix-serve.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
$ask    = Join-Path $RepoRoot 'tools\ask.py'
$chat   = Join-Path $RepoRoot 'tools\chat_server.py'

function Up($url) { try { Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 2 | Out-Null; $true } catch { $false } }

if (-not (Up 'http://127.0.0.1:11434/api/version')) {
    Write-Host 'Starting the AI...'
    Start-Process $ollama -ArgumentList serve -WindowStyle Hidden
}
if (-not $kiwix) { Write-Host "Library not found in $KiwixRoot. Is the drive plugged in? (data_dir in emergency.config.json)"; exit 1 }
if (-not (Up 'http://127.0.0.1:8080')) {
    Write-Host 'Starting the library...'
    # Load every book; skip the smaller Wikipedia editions when a bigger one is present
    $all  = Get-ChildItem "$LibDir\*.zim"
    $skip = if ($all.Name -match '^wikipedia_en_all_maxi_') { '^wikipedia_en_all_(mini|nopic)_' }
            elseif ($all.Name -match '^wikipedia_en_all_nopic_') { '^wikipedia_en_all_mini_' } else { '^$' }
    $zims = $all | Where-Object Name -notmatch $skip | ForEach-Object { "`"$($_.FullName)`"" }
    Start-Process $kiwix -ArgumentList (@('--address=127.0.0.1', '--port=8080') + $zims) -WindowStyle Hidden
}
for ($i = 0; $i -lt 30; $i++) {
    if ((Up 'http://127.0.0.1:8080') -and (Up 'http://127.0.0.1:11434/api/version')) { break }
    Start-Sleep 1
}

if ($Terminal) {
    if (-not $NoBrowser) { Start-Process 'http://127.0.0.1:8080' }
    Write-Host "`nEMERGENCY LIBRARY + AI (model $Model). Type q to quit; run Stop-Emergency.ps1 when done.`n"
    python $ask --model $Model
    exit
}
# Default: the chat page in the browser; it links to the library
if (-not (Up 'http://127.0.0.1:8090/models')) {
    Start-Process python -ArgumentList "`"$chat`"", '--model', $Model -WindowStyle Hidden
    for ($i = 0; $i -lt 10 -and -not (Up 'http://127.0.0.1:8090/models'); $i++) { Start-Sleep 1 }
}
if (-not $NoBrowser) { Start-Process 'http://127.0.0.1:8090' }
Write-Host "`nEMERGENCY HELP is open in the browser: http://127.0.0.1:8090 (model $Model)."
Write-Host 'Double-click "Stop Emergency" when done.'
