// lib/core/utils/numerology/grid.dart
//
// Danh do (tu ten) / Sinh do (tu ngay sinh): dem tan suat chu so 1-9 va xac
// dinh 8 "mui ten" trong luoi Pythagoras 3x3. Xem
// D:\Work\ThanSoHoc\CONG-THUC-THAN-SO-HOC.md, muc 5.

import 'types.dart';

/// 8 duong (3 hang, 3 cot, 2 duong cheo) cua luoi 3x3, dung de xac dinh mui ten.
/// Luoi Pythagoras xep theo tai lieu:
///   3 6 9
///   2 5 8
///   1 4 7
const Map<String, List<int>> gridLines = {
  '3-6-9': [3, 6, 9], // hang tren -- Mui ten sang tri
  '2-5-8': [2, 5, 8], // hang giua -- Mui ten can bang cam xuc
  '1-4-7': [1, 4, 7], // hang duoi -- Mui ten thuc te
  '1-2-3': [1, 2, 3], // cot trai -- Mui ten ke hoach
  '4-5-6': [4, 5, 6], // cot giua -- Mui ten y chi
  '7-8-9': [7, 8, 9], // cot phai -- Mui ten hanh dong
  '1-5-9': [1, 5, 9], // cheo tren-phai -> duoi-trai -- Mui ten quyet tam
  '3-5-7': [3, 5, 7], // cheo tren-trai -> duoi-phai -- Mui ten tam linh
};

/// Dem so lan xuat hien cua tung chu so 1-9 trong [values] (bo qua cac gia
/// tri ngoai khoang 1-9, vi du chu so 0 cua ngay/thang/nam sinh).
Map<int, int> _countDigits(Iterable<int> values) {
  final counts = {for (var d = 1; d <= 9; d++) d: 0};
  for (final v in values) {
    if (v >= 1 && v <= 9) counts[v] = counts[v]! + 1;
  }
  return counts;
}

Map<String, ArrowState> _detectArrows(Map<int, int> counts) {
  final arrows = <String, ArrowState>{};
  for (final entry in gridLines.entries) {
    final presentCount = entry.value.where((d) => counts[d]! > 0).length;
    if (presentCount == 3) {
      arrows[entry.key] = ArrowState.full;
    } else if (presentCount == 0) {
      arrows[entry.key] = ArrowState.empty;
    } else {
      arrows[entry.key] = ArrowState.none;
    }
  }
  return arrows;
}

NumerologyGrid buildGrid(Iterable<int> values) {
  final counts = _countDigits(values);
  return NumerologyGrid(digitCounts: counts, arrows: _detectArrows(counts));
}
