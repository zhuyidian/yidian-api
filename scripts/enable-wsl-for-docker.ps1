#Requires -RunAsAdministrator

$ErrorActionPreference = 'Stop'

$features = @(
    'Microsoft-Windows-Subsystem-Linux',
    'VirtualMachinePlatform'
)

foreach ($feature in $features) {
    Write-Host "Enabling Windows feature: $feature"
    & dism.exe /Online /Enable-Feature /FeatureName:$feature /All /NoRestart

    if ($LASTEXITCODE -notin @(0, 3010)) {
        throw "DISM failed for $feature with exit code $LASTEXITCODE"
    }
}

Write-Host ''
Write-Host 'WSL 2 prerequisites are enabled. Restart Windows before starting Docker Desktop.' -ForegroundColor Green

