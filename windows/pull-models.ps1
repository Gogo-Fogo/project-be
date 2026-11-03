# Download the AI models for this machine. Re-running skips finished models.
#   -Models qwen3.5:4b,gemma4:12b   (default: model and low_battery_model from emergency.config.json)
# Pick models with docs/HARDWARE-AND-MODELS.md. Never load a model bigger than the GPU's memory
# minus 2 GB without the owner at the PC and agreeing: it can freeze Windows.
param([string[]]$Models)
. "$PSScriptRoot\config.ps1"
if ($Cfg.ollama_models) { $env:OLLAMA_MODELS = $Cfg.ollama_models }
if (-not $Models) { $Models = @($Cfg.low_battery_model, $Cfg.model) | Select-Object -Unique }

foreach ($m in $Models) {
    Write-Output "=== $(Get-Date -Format HH:mm:ss) pulling $m"
    ollama pull $m 2>&1 | Select-Object -Last 1
    if ($LASTEXITCODE -ne 0) { Write-Output "!!! FAILED: $m" }
}
Write-Output "=== $(Get-Date -Format HH:mm:ss) done"
ollama list
