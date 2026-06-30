// lib/core/utils/vietnamese_text.dart

/// Loại bỏ dấu tiếng Việt, trả về chuỗi ASCII lowercase để so sánh.
String removeDiacritics(String s) {
  const Map<String, String> diacriticsMap = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ă': 'a',
    'ắ': 'a', 'ặ': 'a', 'ẵ': 'a', 'ẳ': 'a', 'ằ': 'a',
    'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẫ': 'a', 'ẩ': 'a',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ễ': 'e', 'ể': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ơ': 'o',
    'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ỗ': 'o', 'ổ': 'o',
    'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ỡ': 'o', 'ở': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ư': 'u',
    'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ữ': 'u', 'ử': 'u',
    'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỹ': 'y', 'ỷ': 'y',
    'đ': 'd', 'ñ': 'n', 'ç': 'c',
  };
  return s.toLowerCase().split('').map((c) => diacriticsMap[c] ?? c).join();
}
