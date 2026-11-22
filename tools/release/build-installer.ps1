# Builds Setup.exe (and a portable zip) from an existing Windows release build.
# Run it after `flutter build windows --release` in apps/pos_windows, on Windows.
# Used by CI (every pull request) and by the release workflow, so a release is
# built exactly the way CI tested it (ADR-0018).
#
# Output, in <repo>/build/installer:
#   ApparelPoS-Setup-<version>.exe
#   ApparelPoS-<version>-windows-x64.zip   (the app folder, no installer)
#   SHA256SUMS.txt
param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
)
$ErrorActionPreference = 'Stop'

$rel = Join-Path $Root 'apps/pos_windows/build/windows/x64/runner/Release'
if (-not (Test-Path (Join-Path $rel 'pos_windows.exe'))) {
  throw "No Windows release build found in $rel. Run: flutter build windows --release (in apps/pos_windows)"
}

# The Visual C++ runtime next to the app, so a clean laptop does not need the
# redistributable installed (ADR-0018 point 5).
foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
  $src = Join-Path $env:SystemRoot "System32\$dll"
  if (-not (Test-Path $src)) { throw "$dll was not found in System32" }
  Copy-Item $src $rel -Force
}
Get-ChildItem $rel -Filter *.dll | Select-Object Name, Length | Format-Table | Out-String | Write-Host

# The version comes from the app's pubspec (the part before the +).
$match = Select-String -Path (Join-Path $Root 'apps/pos_windows/pubspec.yaml') -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)'
if (-not $match) { throw 'Could not read the version from apps/pos_windows/pubspec.yaml' }
$version = $match.Matches[0].Groups[1].Value

# Inno Setup: already on the runner image, or from Chocolatey.
$iscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe'
if (-not (Test-Path $iscc)) {
  choco install innosetup -y --no-progress
}
if (-not (Test-Path $iscc)) { throw 'Inno Setup is not installed' }

$out = Join-Path $Root 'build/installer'
if (Test-Path $out) { Remove-Item $out -Recurse -Force }
& $iscc "/DAppVersion=$version" (Join-Path $Root 'installer/apparel_pos.iss')
if ($LASTEXITCODE -ne 0) { throw "ISCC failed with exit code $LASTEXITCODE" }

$setup = Join-Path $out "ApparelPoS-Setup-$version.exe"
if (-not (Test-Path $setup)) { throw "Setup was not made at $setup" }

$zip = Join-Path $out "ApparelPoS-$version-windows-x64.zip"
Compress-Archive -Path (Join-Path $rel '*') -DestinationPath $zip -CompressionLevel Optimal

$sums = foreach ($f in $setup, $zip) {
  $h = (Get-FileHash $f -Algorithm SHA256).Hash.ToLower()
  "$h  $(Split-Path $f -Leaf)"
}
$sums | Set-Content -Path (Join-Path $out 'SHA256SUMS.txt') -Encoding ascii
Get-ChildItem $out | Select-Object Name, Length | Format-Table | Out-String | Write-Host
Get-Content (Join-Path $out 'SHA256SUMS.txt') | Write-Host

if ($env:GITHUB_OUTPUT) { "version=$version" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding utf8 }
