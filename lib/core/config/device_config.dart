// lib/core/config/device_config.dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceConfig {
  /// Trả về base API URL phù hợp với thiết bị đang chạy.
  /// Release mode → luôn production.
  /// Debug mode → luôn localUrl (cả emulator lẫn máy thật).
  static Future<String> resolveApiUrl({
    required String localUrl,
    required String prodUrl,
  }) async {
    if (kReleaseMode) return prodUrl;
    return localUrl;
  }
}
