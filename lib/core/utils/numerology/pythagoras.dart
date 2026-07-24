// lib/core/utils/numerology/pythagoras.dart
//
// Bang tra chu cai -> so (bang Pythagoras), xem
// D:\Work\ThanSoHoc\CONG-THUC-THAN-SO-HOC.md, muc 2.

const Map<String, int> vowelValues = {'A': 1, 'E': 5, 'I': 9, 'O': 6, 'U': 3, 'Y': 7};

const Map<String, int> consonantValues = {
  'B': 2, 'C': 3, 'D': 4, 'F': 6, 'G': 7, 'H': 8, 'J': 1, 'K': 2, 'L': 3,
  'M': 4, 'N': 5, 'P': 7, 'Q': 8, 'R': 9, 'S': 1, 'T': 2, 'V': 4, 'W': 5,
  'X': 6, 'Z': 8,
};

/// Gia tri Pythagoras cua 1 ky tu da phan loai trong ten.
class LetterValue {
  final String letter;
  final int value;
  final bool isVowel;

  const LetterValue(this.letter, this.value, this.isVowel);
}

/// Phan loai tung ky tu trong [normalizedName] (da chuan hoa: chu HOA,
/// khong dau tieng Viet -- xem [normalizeNameForNumerology]).
///
/// Tra ve 1 phan tu cho MOI ky tu trong chuoi, `null` neu ky tu do khong
/// phai chu cai A-Z (khoang trang, dau cach...).
///
/// QUY TAC CHU Y (quan trong, da xac minh bang du lieu that trong
/// RIVERSIDE CALCULATION.xlsx, KHONG duoc mo ta dung/ro trong tai lieu
/// .md goc): A/E/I/O/U luon la nguyen am; moi phu am khac luon la phu
/// am; rieng Y: neu ky tu NGAY TRUOC no da duoc xep la nguyen am -> Y la
/// PHU AM; nguoc lai (truoc la phu am, khoang trang, hoac Y la ky tu dau
/// tien) -> Y la NGUYEN AM. Gia tri so cua Y luon la 7 du thuoc hang nao.
List<LetterValue?> classifyName(String normalizedName) {
  final result = <LetterValue?>[];
  var prevIsVowel = false; // ky tu ngay truoc co la nguyen am khong

  for (final ch in normalizedName.split('')) {
    if (ch == 'Y') {
      final isVowel = !prevIsVowel;
      result.add(LetterValue(ch, vowelValues['Y']!, isVowel));
      prevIsVowel = isVowel;
    } else if (vowelValues.containsKey(ch)) {
      result.add(LetterValue(ch, vowelValues[ch]!, true));
      prevIsVowel = true;
    } else if (consonantValues.containsKey(ch)) {
      result.add(LetterValue(ch, consonantValues[ch]!, false));
      prevIsVowel = false;
    } else {
      result.add(null); // khoang trang / ky tu khong thuoc bang chu cai
      prevIsVowel = false;
    }
  }
  return result;
}

/// Chuan hoa ten truoc khi tinh: bo dau tieng Viet, viet HOA, chi giu lai
/// chu cai va khoang trang (loai bo cac ky tu khac neu co).
String normalizeNameForNumerology(String rawName, String Function(String) removeDiacritics) {
  final noDiacritics = removeDiacritics(rawName).toUpperCase();
  return noDiacritics.split('').where((c) => c == ' ' || RegExp(r'[A-Z]').hasMatch(c)).join();
}
