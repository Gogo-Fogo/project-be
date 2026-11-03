# Stops the chat page, the offline library and the local AI on the PC.
Get-CimInstance Win32_Process -Filter "Name='python.exe'" | Where-Object CommandLine -match 'chat_server\.py' |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Stop-Process -Name kiwix-serve, ollama -Force -ErrorAction SilentlyContinue
Write-Host 'Chat, library and AI stopped.'
