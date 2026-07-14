# build-apk.ps1
# Tự động tăng build number (phần sau dấu + trong version) trong pubspec.yaml,
# sau đó build APK release. Dùng script này thay vì gọi `flutter build apk` trực tiếp.

$ErrorActionPreference = "Stop"

$pubspecPath = Join-Path $PSScriptRoot "pubspec.yaml"
$content = Get-Content $pubspecPath -Raw -Encoding UTF8

if ($content -notmatch "(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$") {
    throw "Khong tim thay dong 'version: x.y.z+n' trong pubspec.yaml"
}

$versionName = $Matches[1]
$buildNumber = [int]$Matches[2]
$newBuildNumber = $buildNumber + 1
$newVersionLine = "version: $versionName+$newBuildNumber"

$content = $content -replace "(?m)^version:\s*\d+\.\d+\.\d+\+\d+\s*$", $newVersionLine
Set-Content -Path $pubspecPath -Value $content -Encoding UTF8 -NoNewline

Write-Host "Version: $versionName+$buildNumber -> $versionName+$newBuildNumber" -ForegroundColor Cyan
Write-Host "Building APK release..." -ForegroundColor Cyan

Push-Location $PSScriptRoot
try {
    flutter build apk --release
} finally {
    Pop-Location
}
