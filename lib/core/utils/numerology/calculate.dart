// lib/core/utils/numerology/calculate.dart
//
// Tinh toan cac chi so than so hoc theo dung
// D:\Work\ThanSoHoc\CONG-THUC-THAN-SO-HOC.md (muc 4, 5, 6, 7).
// Da xac minh cong thuc va cac diem mo ho bang du lieu that trong
// RIVERSIDE CALCULATION.xlsx -- xem Plans/than-so-hoc.md.

import 'grid.dart';
import 'pythagoras.dart';
import 'reduce.dart';
import 'types.dart';

ReducedNumber _toReduced(int raw) => ReducedNumber(
      raw: raw,
      display: reduceKeepMaster(raw),
      single: reduceFull(raw),
    );

List<int> _digitsOf(int n) => n.abs().toString().split('').map(int.parse).toList();

/// Tinh toan bo chi so than so hoc cho 1 nguoi.
///
/// [removeDiacritics] duoc truyen vao de tai su dung ham co san
/// lib/core/utils/vietnamese_text.dart (khong import truc tiep de giu
/// module nay thuan Dart, khong phu thuoc cau truc thu muc feature).
NumerologyResult calculateNumerology(
  NumerologyInput input, {
  required String Function(String) removeDiacritics,
}) {
  final normalizedName = normalizeNameForNumerology(input.fullName, removeDiacritics);
  final letters = classifyName(normalizedName);
  final letterValues = letters.whereType<LetterValue>().toList();

  final vowelSum = letterValues.where((l) => l.isVowel).fold(0, (s, l) => s + l.value); // Z3
  final consonantSum = letterValues.where((l) => !l.isVowel).fold(0, (s, l) => s + l.value); // Z5

  final day = input.birthDate.day;
  final month = input.birthDate.month;
  final year = input.birthDate.year;
  final daySum = sumAllDigits(day);
  final monthSum = sumAllDigits(month);
  final yearSum = sumAllDigits(year);

  // Muc 4 -- 6 chi so chinh
  final ngaySinh = _toReduced(daySum);
  final thaiDo = _toReduced(daySum + monthSum);
  final nhanCach = _toReduced(consonantSum);
  final duongDoi = _toReduced(daySum + monthSum + yearSum);
  final linhHon = _toReduced(vowelSum);
  final suMenh = _toReduced(nhanCach.raw + linhHon.raw);

  // Dem tan suat gia tri Pythagoras (1-9) cua tung chu cai trong ten --
  // dung chung cho Noi cam / Chi so thieu / Danh do.
  final nameDigitCounts = {for (var d = 1; d <= 9; d++) d: 0};
  for (final l in letterValues) {
    if (l.value >= 1 && l.value <= 9) nameDigitCounts[l.value] = nameDigitCounts[l.value]! + 1;
  }
  final noiCam = [for (var d = 1; d <= 9; d++) if (nameDigitCounts[d]! > 2) d];
  final chiSoThieu = [for (var d = 1; d <= 9; d++) if (nameDigitCounts[d] == 0) d];

  final ketNoiDuongDoiSuMenh = (duongDoi.single - suMenh.single).abs();
  final ketNoiLinhHonNhanCach = (linhHon.single - nhanCach.single).abs();

  final truongThanh = _toReduced(duongDoi.raw + suMenh.raw);
  final tuoiBatDauTruongThanh = 36 - duongDoi.single;

  // Chi lap trong 6 CS chinh: chu so (1-9) xuat hien nhieu nhat trong 6 gia
  // tri da rut gon triet de; hoa thi lay chu so nho hon (dung thu tu 1..9
  // nhu MATCH dau tien trong Excel).
  final sixCore = [
    ngaySinh.single,
    thaiDo.single,
    nhanCach.single,
    duongDoi.single,
    linhHon.single,
    suMenh.single,
  ];
  final sixCoreCounts = {for (var d = 1; d <= 9; d++) d: 0};
  for (final v in sixCore) {
    if (v >= 1 && v <= 9) sixCoreCounts[v] = sixCoreCounts[v]! + 1;
  }
  var chiLapTrong6CSChinh = sixCore.first;
  var bestCount = 0;
  for (var d = 1; d <= 9; d++) {
    if (sixCoreCounts[d]! > bestCount) {
      bestCount = sixCoreCounts[d]!;
      chiLapTrong6CSChinh = d;
    }
  }

  // Chi so can bang: cong gia tri Pythagoras cua chu cai dau MOI tu trong ten.
  var canBangRaw = 0;
  var atWordStart = true;
  for (var i = 0; i < normalizedName.length; i++) {
    final c = normalizedName[i];
    if (c == ' ') {
      atWordStart = true;
      continue;
    }
    if (atWordStart) {
      canBangRaw += letters[i]?.value ?? 0;
      atWordStart = false;
    }
  }
  final canBang = _toReduced(canBangRaw);

  // Muc 5 -- Danh do / Sinh do
  final danhDo = buildGrid(letterValues.map((l) => l.value));
  final birthDigits = [..._digitsOf(day), ..._digitsOf(month), ..._digitsOf(year)];
  final sinhDo = buildGrid(birthDigits);

  // Muc 6 -- Nam/Thang/Ngay ca nhan (dua tren ngay lap la so, chartDate)
  final refDay = input.chartDate.day;
  final refMonth = input.chartDate.month;
  final refYear = input.chartDate.year;
  final namCaNhan = _toReduced(daySum + monthSum + sumAllDigits(refYear));
  final thangCaNhan = _toReduced(namCaNhan.display + sumAllDigits(refMonth));
  final ngayCaNhan = _toReduced(thangCaNhan.display + sumAllDigits(refDay));

  // Muc 7 -- 4 dinh cao / 4 thu thach / 3 giai doan
  final ag34 = reduceKeepMaster(daySum); // Ngay sinh rut gon
  final ag35 = reduceKeepMaster(monthSum); // Thang sinh rut gon
  final ag36 = reduceKeepMaster(yearSum); // Nam sinh rut gon

  final peak1 = _toReduced(ag35 + ag34);
  final peak2 = _toReduced(ag34 + ag36);
  final peak3 = _toReduced(peak1.display + peak2.display);
  final peak4 = _toReduced(ag35 + ag36);
  final startAge1 = 36 - duongDoi.single;
  final dinhCao = [
    PeakInfo(value: peak1, startAge: startAge1),
    PeakInfo(value: peak2, startAge: startAge1 + 9),
    PeakInfo(value: peak3, startAge: startAge1 + 18),
    PeakInfo(value: peak4, startAge: startAge1 + 27),
  ];

  final challenge1 = _toReduced((ag34 - ag35).abs());
  final challenge2 = _toReduced((ag34 - ag36).abs());
  final challenge3 = _toReduced((challenge1.display - challenge2.display).abs());
  final challenge4 = _toReduced((ag35 - ag36).abs());
  final thuThach = [challenge1, challenge2, challenge3, challenge4];

  final baGiaiDoan = LifeStages(tienVan: ag35, trungVan: ag34, hauVan: ag36);

  return NumerologyResult(
    ngaySinh: ngaySinh,
    thaiDo: thaiDo,
    nhanCach: nhanCach,
    duongDoi: duongDoi,
    linhHon: linhHon,
    suMenh: suMenh,
    noiCam: noiCam,
    ketNoiDuongDoiSuMenh: ketNoiDuongDoiSuMenh,
    ketNoiLinhHonNhanCach: ketNoiLinhHonNhanCach,
    truongThanh: truongThanh,
    tuoiBatDauTruongThanh: tuoiBatDauTruongThanh,
    chiSoThieu: chiSoThieu,
    chiLapTrong6CSChinh: chiLapTrong6CSChinh,
    canBang: canBang,
    danhDo: danhDo,
    sinhDo: sinhDo,
    namCaNhan: namCaNhan,
    thangCaNhan: thangCaNhan,
    ngayCaNhan: ngayCaNhan,
    dinhCao: dinhCao,
    thuThach: thuThach,
    baGiaiDoan: baGiaiDoan,
  );
}
