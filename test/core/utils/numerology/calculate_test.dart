// test/core/utils/numerology/calculate_test.dart
//
// Doi chieu voi golden case da xac minh bang tay tu du lieu that trong
// RIVERSIDE CALCULATION.xlsx (sheet "xm") -- xem Plans/than-so-hoc.md.
// Ho ten: NGUYEN THI HANG, sinh 10/10/1997, ngay lap la so 10/12/2023.
//
// Luu y: Chi so Can bang ky vong = 6 (khong phai 7 nhu doc thay trong file
// Excel mau) -- file mau bi loi nhap lieu o 1 o phan cach tu (xem ghi chu
// trong Plans/than-so-hoc.md), da co chu dich cai dat dung theo mo ta trong
// tai lieu cong thuc (cong chu cai dau CUA TAT CA cac tu).

import 'package:flutter_test/flutter_test.dart';
import 'package:quan_ly_gas_app/core/utils/numerology/calculate.dart';
import 'package:quan_ly_gas_app/core/utils/numerology/types.dart';
import 'package:quan_ly_gas_app/core/utils/vietnamese_text.dart';

String _upperRemoveDiacritics(String s) => removeDiacritics(s).toUpperCase();

void main() {
  final input = NumerologyInput(
    fullName: 'NGUYEN THI HANG',
    birthDate: DateTime(1997, 10, 10),
    chartDate: DateTime(2023, 12, 10),
  );
  final result = calculateNumerology(input, removeDiacritics: _upperRemoveDiacritics);

  group('6 chi so chinh', () {
    test('Ngay sinh = 1 (raw 1)', () {
      expect(result.ngaySinh.raw, 1);
      expect(result.ngaySinh.display, 1);
    });

    test('Thai do = 2', () {
      expect(result.thaiDo.display, 2);
    });

    test('Nhan cach = 9 (raw 54)', () {
      expect(result.nhanCach.raw, 54);
      expect(result.nhanCach.display, 9);
    });

    test('Duong doi = 1 (raw 28)', () {
      expect(result.duongDoi.raw, 28);
      expect(result.duongDoi.display, 1);
      expect(result.duongDoi.single, 1);
    });

    test('Linh hon = 9 (raw 18)', () {
      expect(result.linhHon.raw, 18);
      expect(result.linhHon.display, 9);
    });

    test('Su menh = 9 (raw 72)', () {
      expect(result.suMenh.raw, 72);
      expect(result.suMenh.display, 9);
    });
  });

  group('Chi so bo tro', () {
    test('Noi cam gom 5 va 7', () {
      expect(result.noiCam, containsAll(<int>[5, 7]));
      expect(result.noiCam.length, 2);
    });

    test('Ket noi Duong doi - Su menh = 8', () {
      expect(result.ketNoiDuongDoiSuMenh, 8);
    });

    test('Ket noi Linh hon - Nhan cach = 0', () {
      expect(result.ketNoiLinhHonNhanCach, 0);
    });

    test('Truong thanh = 1 (raw 100)', () {
      expect(result.truongThanh.raw, 100);
      expect(result.truongThanh.display, 1);
    });

    test('Tuoi bat dau truong thanh = 35', () {
      expect(result.tuoiBatDauTruongThanh, 35);
    });

    test('Chi so thieu gom 4 va 6', () {
      expect(result.chiSoThieu, containsAll(<int>[4, 6]));
      expect(result.chiSoThieu.length, 2);
    });

    test('Chi lap trong 6 CS chinh = 9', () {
      expect(result.chiLapTrong6CSChinh, 9);
    });

    test('Can bang = 6 (raw 15) -- KHAC voi so 7 doc thay trong file Excel mau '
        'do loi nhap lieu o file mau, xem ghi chu dau file test', () {
      expect(result.canBang.raw, 15);
      expect(result.canBang.display, 6);
    });
  });

  group('4 dinh cao va tuoi bat dau', () {
    test('Gia tri 4 dinh cao la 2, 9, 11, 9', () {
      expect(result.dinhCao.map((p) => p.value.display).toList(), [2, 9, 11, 9]);
    });

    test('Tuoi bat dau 4 dinh cao la 35, 44, 53, 62', () {
      expect(result.dinhCao.map((p) => p.startAge).toList(), [35, 44, 53, 62]);
    });
  });

  group('4 thu thach', () {
    test('Gia tri 4 thu thach la 0, 7, 7, 7', () {
      expect(result.thuThach.map((c) => c.display).toList(), [0, 7, 7, 7]);
    });
  });

  group('3 giai doan cuoc doi', () {
    test('Tien van = 1, Trung van = 1, Hau van = 8', () {
      expect(result.baGiaiDoan.tienVan, 1);
      expect(result.baGiaiDoan.trungVan, 1);
      expect(result.baGiaiDoan.hauVan, 8);
    });
  });
}
