# PowerShell Script Unblock Helper
# Run this as Administrator in PowerShell

Write-Host "Unblocking downloaded PowerShell scripts..." -ForegroundColor Yellow

# Unblock the system_hardening.ps1 script
$scriptPath = "C:\Users\Asus\Downloads\system_hardening.ps1"
if (Test-Path $scriptPath) {
    Unblock-File -Path $scriptPath
    Write-Host "✓ Unblocked: $scriptPath" -ForegroundColor Green
} else {
    Write-Host "✗ Script not found: $scriptPath" -ForegroundColor Red
}

# Also unblock system_diagnostics.ps1 if it exists
$diagPath = "C:\Users\Asus\Downloads\system_diagnostics.ps1"
if (Test-Path $diagPath) {
    Unblock-File -Path $diagPath
    Write-Host "✓ Unblocked: $diagPath" -ForegroundColor Green
} else {
    Write-Host "✗ Diagnostics script not found: $diagPath" -ForegroundColor Yellow
}

Write-Host "`nNow you can run the scripts normally:" -ForegroundColor Cyan
Write-Host "powershell.exe -ExecutionPolicy Bypass -File `"$scriptPath`"" -ForegroundColor White
Write-Host "or simply: .\system_hardening.ps1" -ForegroundColor White