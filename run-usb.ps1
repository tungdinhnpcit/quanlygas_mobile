# run-usb.ps1 — Chạy app trên thiết bị thật, kết nối BE qua CABLE USB (không WiFi).
# Luồng: thiết bị gọi localhost:5001 -> adb reverse tunnel qua USB -> BE trên máy dev (0.0.0.0:5001).
#
# Dùng:  .\run-usb.ps1                (tự chọn thiết bị android đầu tiên)
#        .\run-usb.ps1 -Port 5001     (đổi port nếu BE chạy port khác)
#        .\run-usb.ps1 -DeviceId xxx  (chỉ định thiết bị cụ thể)

param(
    [int]$Port       = 5001,
    [string]$DeviceId = ""
)

$ErrorActionPreference = "Stop"
$adb = "D:\Sdk\platform-tools\adb.exe"

Write-Host "=== Run App qua USB (adb reverse + flutter run) ===" -ForegroundColor Cyan

# 1) Kiểm tra thiết bị android đang cắm
$devices = & $adb devices | Select-String "`tdevice$" | ForEach-Object { ($_ -split "`t")[0] }
if (-not $devices) {
    Write-Host "[ERROR] Khong tim thay thiet bi Android. Cam cap USB + bat USB debugging." -ForegroundColor Red
    exit 1
}
if (-not $DeviceId) { $DeviceId = $devices | Select-Object -First 1 }
Write-Host "Thiet bi : $DeviceId" -ForegroundColor Green
Write-Host "Port BE  : $Port"

# 2) Bat tunnel USB: localhost:Port tren device -> localhost:Port tren may dev
& $adb -s $DeviceId reverse "tcp:$Port" "tcp:$Port" | Out-Null
Write-Host "adb reverse: tcp:$Port -> tcp:$Port (OK)" -ForegroundColor Green

# 3) Canh bao neu BE chua listen
$listening = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if (-not $listening) {
    Write-Host "[WARN] Chua co process nao listen tren port $Port — nho khoi dong BE dev truoc." -ForegroundColor Yellow
}

# 4) Chay app (debug mode -> app tu dung http://127.0.0.1:$Port)
Write-Host "Dang chay flutter run..." -ForegroundColor Cyan
flutter run -d $DeviceId
