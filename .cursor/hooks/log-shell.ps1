# beforeShellExecution — allow all, emit valid JSON
$ErrorActionPreference = 'SilentlyContinue'
try {
  $null = [Console]::In.ReadToEnd()
} catch {}
Write-Output '{"permission":"allow"}'
