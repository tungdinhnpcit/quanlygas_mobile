# Đợi emulator-5556 online rồi setup reverse tunnel
# Dùng sau khi flutter run đã bắt đầu kết nối

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$device = "emulator-5556"

Write-Host "Chờ emulator $device sẵn sàng..."
& $adb -s $device wait-for-device

Write-Host "Setup reverse tunnel tcp:5001..."
& $adb -s $device reverse tcp:5001 tcp:5001

Write-Host "Tunnel active:"
& $adb -s $device reverse --list
