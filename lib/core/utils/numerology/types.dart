// lib/core/utils/numerology/types.dart

/// Du lieu dau vao de tinh cac chi so than so hoc.
class NumerologyInput {
  /// Ho ten day du (co the co dau tieng Viet, se duoc chuan hoa truoc khi tinh).
  final String fullName;
  final DateTime birthDate;

  /// Ngay dung de tinh Nam/Thang/Ngay ca nhan (mac dinh la hom nay).
  final DateTime chartDate;

  const NumerologyInput({
    required this.fullName,
    required this.birthDate,
    required this.chartDate,
  });
}

/// Ket qua rut gon cua 1 chi so: gia tri tho, gia tri hien thi (giu so chu
/// dao 11/22/33 neu co) va gia tri rut gon triet de (luon 1 chu so, dung de
/// so sanh/doi chieu).
class ReducedNumber {
  final int raw;
  final int display;
  final int single;

  const ReducedNumber({required this.raw, required this.display, required this.single});
}

/// 1 trong 4 dinh cao cua cuoc doi.
class PeakInfo {
  final ReducedNumber value;
  final int startAge;

  const PeakInfo({required this.value, required this.startAge});
}

/// 3 giai doan cuoc doi (Tien van / Trung van / Hau van).
class LifeStages {
  final int tienVan; // Thang sinh da rut gon (AG35)
  final int trungVan; // Ngay sinh da rut gon (AG34)
  final int hauVan; // Nam sinh da rut gon (AG36)

  const LifeStages({required this.tienVan, required this.trungVan, required this.hauVan});
}

/// Luoi Danh do / Sinh do: dem tan suat cac chu so 1-9 va xac dinh 8 "mui ten".
enum ArrowState { full, empty, none }

class NumerologyGrid {
  /// So lan xuat hien cua tung chu so 1-9.
  final Map<int, int> digitCounts;

  /// Trang thai 8 duong (3 hang, 3 cot, 2 duong cheo), key la ten nhan dien
  /// nhu tai lieu (VD "3-6-9", "1-5-9"...).
  final Map<String, ArrowState> arrows;

  const NumerologyGrid({required this.digitCounts, required this.arrows});
}

/// Toan bo ket qua tinh than so hoc cho 1 nguoi, theo dung
/// D:\Work\ThanSoHoc\CONG-THUC-THAN-SO-HOC.md muc 4, 5, 6, 7.
class NumerologyResult {
  // Muc 4 -- 6 chi so chinh
  final ReducedNumber ngaySinh;
  final ReducedNumber thaiDo;
  final ReducedNumber nhanCach;
  final ReducedNumber duongDoi;
  final ReducedNumber linhHon;
  final ReducedNumber suMenh;

  // Muc 4 -- cac chi so bo tro
  final List<int> noiCam; // chu so (1-9) xuat hien > 2 lan trong ten
  final int ketNoiDuongDoiSuMenh; // |duong doi - su menh| (da rut gon triet de)
  final int ketNoiLinhHonNhanCach; // |linh hon - nhan cach| (da rut gon triet de)
  final ReducedNumber truongThanh;
  final int tuoiBatDauTruongThanh;
  final List<int> chiSoThieu; // chu so (1-9) khong xuat hien trong ten
  final int chiLapTrong6CSChinh; // chu so xuat hien nhieu nhat trong 6 CS chinh (da rut gon triet de)
  final ReducedNumber canBang;

  // Muc 5 -- luoi Pythagoras
  final NumerologyGrid danhDo; // tu ten
  final NumerologyGrid sinhDo; // tu ngay sinh

  // Muc 6 -- chu ky ca nhan
  final ReducedNumber namCaNhan;
  final ReducedNumber thangCaNhan;
  final ReducedNumber ngayCaNhan;

  // Muc 7 -- dinh cao / thu thach / giai doan
  final List<PeakInfo> dinhCao; // 4 phan tu
  final List<ReducedNumber> thuThach; // 4 phan tu
  final LifeStages baGiaiDoan;

  const NumerologyResult({
    required this.ngaySinh,
    required this.thaiDo,
    required this.nhanCach,
    required this.duongDoi,
    required this.linhHon,
    required this.suMenh,
    required this.noiCam,
    required this.ketNoiDuongDoiSuMenh,
    required this.ketNoiLinhHonNhanCach,
    required this.truongThanh,
    required this.tuoiBatDauTruongThanh,
    required this.chiSoThieu,
    required this.chiLapTrong6CSChinh,
    required this.canBang,
    required this.danhDo,
    required this.sinhDo,
    required this.namCaNhan,
    required this.thangCaNhan,
    required this.ngayCaNhan,
    required this.dinhCao,
    required this.thuThach,
    required this.baGiaiDoan,
  });
}
