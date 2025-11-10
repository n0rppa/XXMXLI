Param(
  [string]$Python = "python"
)

$ErrorActionPreference = 'Stop'
Write-Host "==> Building incident tools (Windows)" -ForegroundColor Cyan

$scripts = @(
  @{ Path = 'automated_incident_reporter.py'; Name = 'incident-reporter' },
  @{ Path = 'EASY_LAUNCHER.py'; Name = 'incident-launcher' }
)

if (-not (Get-Command $Python -ErrorAction SilentlyContinue)) {
  Write-Error "Python executable not found: $Python"
}

$dist = Join-Path (Get-Location) 'dist_executables'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

foreach ($s in $scripts) {
  Write-Host "Building $($s.Path) -> $($s.Name).exe" -ForegroundColor Yellow
  & $Python -m PyInstaller --onefile --name $s.Name $s.Path
  Copy-Item "dist/$($s.Name).exe" $dist -Force
  Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
  Remove-Item "$($s.Name).spec" -ErrorAction SilentlyContinue
}

Write-Host "All builds complete. EXEs in $dist" -ForegroundColor Green