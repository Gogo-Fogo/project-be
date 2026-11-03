# Loads emergency.config.json from the repo root (copy emergency.config.example.json and edit it).
# Every Windows script dot-sources this: . "$PSScriptRoot\config.ps1"
$RepoRoot = Split-Path $PSScriptRoot -Parent
$cfgFile  = Join-Path $RepoRoot 'emergency.config.json'
$Cfg = [ordered]@{
    data_dir          = 'C:\Emergency'
    ollama_models     = ''              # empty = Ollama's default folder
    model             = 'qwen3.5:4b'
    low_battery_model = 'qwen3.5:2b-q4_K_M'
    library_tier      = 'medium'        # small | medium | large, see docs/LIBRARY.md
    emergency_number  = '911'
    gpu_overhead_gb   = 2               # VRAM kept free for the screen (see docs/HARDWARE-AND-MODELS.md)
}
if (Test-Path $cfgFile) {
    (Get-Content $cfgFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $Cfg[$_.Name] = $_.Value }
}
$KiwixRoot = Join-Path $Cfg.data_dir 'Kiwix'
$LibDir    = Join-Path $KiwixRoot 'library'
$AppsDir   = Join-Path $KiwixRoot 'apps'
$VideoDir  = Join-Path $Cfg.data_dir 'Videos'
$GamesDir  = Join-Path $Cfg.data_dir 'Games'
$env:EMERGENCY_NUMBER = $Cfg.emergency_number
