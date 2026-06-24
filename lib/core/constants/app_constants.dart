// lib/core/constants/app_constants.dart
class AppConstants {
  static const String notificationChannelId = 'quan_ly_gas_channel';
  static const String notificationChannelName = 'QuanLyGas Thông Báo';
  static const String notificationChannelDesc =
      'Thông báo chuyến xe và cập nhật từ hệ thống';
  static const String localApiUrl = 'http://192.168.31.123:5001';
  static const String prodApiUrl  = 'http://apimba.npc.com.vn:8202/apimanager';
  // Được set bởi DeviceConfig.resolveApiUrl() trong main() trước khi runApp
  static String resolvedApiUrl = prodApiUrl;
  static const String lichTuanApiUrl =
      'https://lichtuan.npc.com.vn/LT_WebAPI/api/PageBase/LichtuanNVJson';
  static const String lichTuanMaDviqly = 'NPCIT';
  static const String lichTuanXacThuc = 'Auth';
  static const int lichTuanNvid = 1303;
}
