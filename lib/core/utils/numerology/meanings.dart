// lib/core/utils/numerology/meanings.dart
//
// Tra cuu van ban dien giai y nghia. Chi 4 chi so co bang tra trong file
// nguon "TSH Hien Mira _ Tong hop thong tin cac chi so.xlsx": Duong doi
// (1-11,22,33), Ngay sinh (1-31), Ten khai sinh/Su menh (1-11), Thai do
// (1-11,22,33). Cac chi so con lai (Nhan cach, Linh hon, Truong thanh,
// Can bang, Dinh cao, Thu thach, chu ky ca nhan, mui ten...) khong co bang
// tra y nghia (dung nhu muc 8 tai lieu goc), chi hien thi so/nhan.

import 'meanings_data.dart';

const String khongCoDuLieuYNghia = 'Chưa có dữ liệu diễn giải cho chỉ số này.';

String _lookup(Map<int, String> table, int value) {
  final text = table[value];
  if (text == null || text.isEmpty) return khongCoDuLieuYNghia;
  return text;
}

String duongDoiMeaning(int value) => _lookup(duongDoiMeanings, value);

String ngaySinhMeaning(int value) => _lookup(ngaySinhMeanings, value);

String tenKhaiSinhMeaning(int value) => _lookup(tenKhaiSinhMeanings, value);

String thaiDoMeaning(int value) => _lookup(thaiDoMeanings, value);
