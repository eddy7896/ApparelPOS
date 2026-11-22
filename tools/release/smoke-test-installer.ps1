# Installs Setup silently into a temp folder, checks the files, starts the app
# for 10 seconds, then uninstalls it. Run on Windows after build-installer.ps1.
# Used by CI and by the release workflow.
param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
)
$ErrorActionPreference = 'Stop'

$setup = (Get-ChildItem (Join-Path $Root 'build/installer/ApparelPoS-Setup-*.exe') | Select-Object -First 1).FullName
$temp = if ($env:RUNNER_TEMP) { $env:RUNNER_TEMP } else { $env:TEMP }
$dir = Join-Path $temp 'ApparelPoS-test'
$log = Join-Path $temp 'setup.log'
$p = Start-Process $setup -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/DIR=`"$dir`"", "/LOG=`"$log`"" -Wait -PassThru
if ($p.ExitCode -ne 0) { Get-Content $log -Tail 40; throw "Setup exited with $($p.ExitCode)" }

Get-ChildItem $dir | Select-Object Name, Length | Format-Table | Out-String | Write-Host
# the SQLite library comes from the sqlite3 build hook (SQLCipher); require one
if (-not (Get-ChildItem $dir -Filter *.dll | Where-Object { $_.Name -match 'sqlite3|sqlcipher' })) {
  throw 'no SQLite/SQLCipher library was installed'
}
foreach ($f in 'pos_windows.exe', 'flutter_windows.dll', 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll', 'unins000.exe') {
  if (-not (Test-Path (Join-Path $dir $f))) { throw "$f is missing after install" }
}
if (-not (Test-Path (Join-Path $dir 'data\flutter_assets'))) { throw 'the app data folder is missing after install' }

$app = Start-Process (Join-Path $dir 'pos_windows.exe') -PassThru
Start-Sleep -Seconds 10
if ($app.HasExited) { throw "the installed app stopped within 10 seconds (exit code $($app.ExitCode))" }
Stop-Process -Id $app.Id -Force

Start-Process (Join-Path $dir 'unins000.exe') -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait | Out-Null
Start-Sleep -Seconds 3
if (Test-Path (Join-Path $dir 'pos_windows.exe')) { throw 'the app is still there after uninstall' }
Write-Host 'Installer smoke test passed.'
