# afterFileEdit — observe only, emit empty JSON object
$ErrorActionPreference = 'SilentlyContinue'
try {
  $null = [Console]::In.ReadToEnd()
} catch {}
Write-Output '{}'
