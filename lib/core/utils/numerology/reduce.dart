// lib/core/utils/numerology/reduce.dart
//
// Cac ham "rut gon" dung xuyen suot cong thuc than so hoc (xem
// D:\Work\ThanSoHoc\CONG-THUC-THAN-SO-HOC.md, muc 3).
//
// Co 2 loai ham khac nhau, KHONG duoc nham lan:
// - [sumAllDigits]: cong TAT CA cac chu so cua mot so (vi du 1997 -> 1+9+9+7 = 26).
//   Dung MOT LAN de tinh cac tong "tho" ban dau (VD chi so ngay sinh/thai
//   do/duong doi tu ngay-thang-nam sinh), giong cach Excel cong tung o
//   chu so rieng le (SUM(E6:F6), SUM(M6:P6)...).
// - [reduceOnce]/[reduceKeepMaster]/[reduceFull]: buoc "rut gon" lap lai
//   dung CHINH XAC cong thuc Excel goc `ROUNDDOWN(X/10,0) + X - ROUNDDOWN(X/10,0)*10`
//   (tuong duong `x ~/ 10 + x % 10`). Luu y: voi so >= 100, buoc nay KHAC
//   voi cong tat ca chu so trong 1 lan (vi du 487 -> 48 + 7 = 55, khong
//   phai 4+8+7=19) -- nhung se hoi tu ve cung 1 gia tri cuoi cung sau vai
//   lan lap. Phai dung dung ham nay (khong duoc thay bang sumAllDigits lap
//   lai) vi viec phat hien so chu dao (11/22/33) phu thuoc vao gia tri
//   trung gian chinh xac tung buoc, da xac minh bang du lieu that trong
//   RIVERSIDE CALCULATION.xlsx.

const Set<int> masterNumbers = {11, 22, 33};

/// Cong tat ca chu so cua [n] (vi du 1997 -> 26, 19 -> 10, 5 -> 5).
int sumAllDigits(int n) {
  var x = n.abs();
  var s = 0;
  while (x > 0) {
    s += x % 10;
    x ~/= 10;
  }
  return s;
}

/// Mot buoc rut gon dung cong thuc Excel goc: x~/10 + x%10.
int reduceOnce(int x) => x ~/ 10 + x % 10;

/// Rut gon lap lai toi khi < 10 HOAC la so chu dao (11, 22, 33) -- giu
/// nguyen so chu dao neu gap phai trong qua trinh rut gon.
int reduceKeepMaster(int x) {
  var v = x;
  while (v >= 10 && !masterNumbers.contains(v)) {
    v = reduceOnce(v);
  }
  return v;
}

/// Rut gon lap lai toi khi < 10, bo qua so chu dao (luon ve 1 chu so).
int reduceFull(int x) {
  var v = x;
  while (v >= 10) {
    v = reduceOnce(v);
  }
  return v;
}
