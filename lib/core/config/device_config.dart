// lib/core/config/device_config.dart
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceConfig {
  /// Trả về base API URL phù hợp với thiết bị đang chạy.
  /// Release mode → luôn production (bất kể emulator hay máy thật).
  /// Debug mode + emulator/simulator → localUrl (BE local).
  /// Debug mode + máy thật → prodUrl.
  static Future<String> resolveApiUrl({
    required String localUrl,
    required String prodUrl,
  }) async {
    if (kReleaseMode) return prodUrl;

    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return info.isPhysicalDevice ? prodUrl : localUrl;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return info.isPhysicalDevice ? prodUrl : localUrl;
      }
    } catch (_) {}

    return prodUrl;
  }
}
