// lib/core/utils/app_scale.dart
import 'dart:math';
import 'package:flutter/widgets.dart';

/// Tính scale factor dựa trên kích thước vật lý màn hình.
/// Công thức: diagonal(dp) / 160 ≈ diagonal(inch) theo chuẩn Android (1dp = 1/160 inch).
class AppScale {
  static const double _largeTabletMinInch = 9.0;
  static const double _largeTabletFactor = 1.3;

  /// Trả về scale factor cho text và icon:
  /// - Phone + 8-inch tablet (< 9"): 1.0 (giữ nguyên thiết kế)
  /// - Tablet 10-inch trở lên (>= 9"): 1.3 (font và icon to hơn 30%)
  static double factor(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final diagonalInch =
        sqrt(size.width * size.width + size.height * size.height) / 160.0;
    if (diagonalInch >= _largeTabletMinInch) return _largeTabletFactor;
    return 1.0;
  }
}
