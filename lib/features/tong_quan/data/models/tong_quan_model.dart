// lib/features/tong_quan/data/models/tong_quan_model.dart

class DoanhThuItem {
  final DateTime ngay;
  final double tongTienThu;
  final int soChuyenXe;

  DoanhThuItem({required this.ngay, required this.tongTienThu, required this.soChuyenXe});

  factory DoanhThuItem.fromJson(Map<String, dynamic> j) => DoanhThuItem(
        ngay: DateTime.parse(j['ngay']),
        tongTienThu: (j['tongTienThu'] as num).toDouble(),
        soChuyenXe: j['soChuyenXe'] as int,
      );
}

class DoanhThuResult {
  final double tongCong;
  final List<DoanhThuItem> items;

  DoanhThuResult({required this.tongCong, required this.items});

  factory DoanhThuResult.fromJson(Map<String, dynamic> j) => DoanhThuResult(
        tongCong: (j['tongCong'] as num).toDouble(),
        items: (j['items'] as List).map((e) => DoanhThuItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class TonKhoItem {
  final String tenMatHang;
  final String donViTinh;
  final int tongNhap;
  final int tongXuat;
  final int tonHienTai;

  TonKhoItem({
    required this.tenMatHang,
    required this.donViTinh,
    required this.tongNhap,
    required this.tongXuat,
    required this.tonHienTai,
  });

  factory TonKhoItem.fromJson(Map<String, dynamic> j) => TonKhoItem(
        tenMatHang: j['tenMatHang'] ?? '',
        donViTinh: j['donViTinh'] ?? '',
        tongNhap: (j['tongNhap'] as num).toInt(),
        tongXuat: (j['tongXuat'] as num).toInt(),
        tonHienTai: (j['tonHienTai'] as num).toInt(),
      );
}

class NhapXuatItem {
  final String tenMatHang;
  final int tongNhap;
  final int tongXuat;

  NhapXuatItem({required this.tenMatHang, required this.tongNhap, required this.tongXuat});

  factory NhapXuatItem.fromJson(Map<String, dynamic> j) => NhapXuatItem(
        tenMatHang: j['tenMatHang'] ?? '',
        tongNhap: (j['tongNhap'] as num).toInt(),
        tongXuat: (j['tongXuat'] as num).toInt(),
      );
}

class TongQuanData {
  final DoanhThuResult doanhThu;
  final List<TonKhoItem> tonKho;
  final List<NhapXuatItem> nhapXuat;

  TongQuanData({required this.doanhThu, required this.tonKho, required this.nhapXuat});
}

// ── Dashboard tổng quan mới ──────────────────────────────────────────────────

class BinhBanItem {
  final int matHangId;
  final String tenMatHang;
  final String? tenNhaCungCap;
  final int soLuong;
  final double thanhTien;

  BinhBanItem({
    required this.matHangId,
    required this.tenMatHang,
    this.tenNhaCungCap,
    required this.soLuong,
    required this.thanhTien,
  });

  factory BinhBanItem.fromJson(Map<String, dynamic> j) => BinhBanItem(
        matHangId:     j['matHangId'] as int,
        tenMatHang:    j['tenMatHang'] ?? '',
        tenNhaCungCap: j['tenNhaCungCap'] as String?,
        soLuong:       (j['soLuong'] as num).toInt(),
        thanhTien:     (j['thanhTien'] as num).toDouble(),
      );
}

class DaiLyItem {
  final int khachHangId;
  final String maKhachHang;
  final String tenKhachHang;
  final int soLuong;
  final double thanhTien;
  final double tienNo;
  final DateTime? ngayMuaCuoiCung;
  final int? soNgayChuaMua;

  DaiLyItem({
    required this.khachHangId,
    required this.maKhachHang,
    required this.tenKhachHang,
    required this.soLuong,
    required this.thanhTien,
    required this.tienNo,
    this.ngayMuaCuoiCung,
    this.soNgayChuaMua,
  });

  factory DaiLyItem.fromJson(Map<String, dynamic> j) => DaiLyItem(
        khachHangId:     j['khachHangId'] as int,
        maKhachHang:     j['maKhachHang'] ?? '',
        tenKhachHang:    j['tenKhachHang'] ?? '',
        soLuong:         (j['soLuong'] as num).toInt(),
        thanhTien:       (j['thanhTien'] as num).toDouble(),
        tienNo:          (j['tienNo'] as num).toDouble(),
        ngayMuaCuoiCung: j['ngayMuaCuoiCung'] != null
            ? DateTime.tryParse(j['ngayMuaCuoiCung'] as String)
            : null,
        soNgayChuaMua: j['soNgayChuaMua'] as int?,
      );
}

// ── Chi tiết bán hàng theo đại lý ───────────────────────────────────────────

class DaiLyBanHangChiTietModel {
  final int matHangId;
  final String tenMatHang;
  final int soLuong;
  final double giaBan;
  final double thanhTien;

  DaiLyBanHangChiTietModel({
    required this.matHangId,
    required this.tenMatHang,
    required this.soLuong,
    required this.giaBan,
    required this.thanhTien,
  });

  factory DaiLyBanHangChiTietModel.fromJson(Map<String, dynamic> j) =>
      DaiLyBanHangChiTietModel(
        matHangId:  j['matHangId'] as int,
        tenMatHang: j['tenMatHang'] ?? '',
        soLuong:    (j['soLuong'] as num).toInt(),
        giaBan:     (j['giaBan'] as num).toDouble(),
        thanhTien:  (j['thanhTien'] as num).toDouble(),
      );
}

class DaiLyBanHangModel {
  final int chuyenXeId;
  final String maChuyenXe;
  final DateTime ngayXuat;
  final List<DaiLyBanHangChiTietModel> chiTiet;
  final double tongTienBan;
  final double tienNo;
  final String? anhUrl;       // ảnh biên lai ký tay của khách trong chuyến
  final String? chuKyUrl;     // chữ ký vẽ trên app của khách trong chuyến

  DaiLyBanHangModel({
    required this.chuyenXeId,
    required this.maChuyenXe,
    required this.ngayXuat,
    required this.chiTiet,
    required this.tongTienBan,
    required this.tienNo,
    this.anhUrl,
    this.chuKyUrl,
  });

  factory DaiLyBanHangModel.fromJson(Map<String, dynamic> j) =>
      DaiLyBanHangModel(
        chuyenXeId:  j['chuyenXeId'] as int,
        maChuyenXe:  j['maChuyenXe'] ?? '',
        ngayXuat:    DateTime.parse(j['ngayXuat']),
        chiTiet:     (j['chiTiet'] as List)
            .map((e) => DaiLyBanHangChiTietModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        tongTienBan: (j['tongTienBan'] as num).toDouble(),
        tienNo:      (j['tienNo'] as num).toDouble(),
        anhUrl:      j['anhUrl'] as String?,
        chuKyUrl:    j['chuKyUrl'] as String?,
      );
}

// ── Đại lý lâu chưa mua ─────────────────────────────────────────────────────

class KhachHangChuaMuaModel {
  final int khachHangId;
  final String maKhachHang;
  final String tenKhachHang;
  final String? soDienThoai;
  final String? diaChi;
  final DateTime? ngayMuaCuoiCung;
  final int? soNgayChuaMua;
  final double? latitude;
  final double? longitude;

  KhachHangChuaMuaModel({
    required this.khachHangId,
    required this.maKhachHang,
    required this.tenKhachHang,
    this.soDienThoai,
    this.diaChi,
    this.ngayMuaCuoiCung,
    this.soNgayChuaMua,
    this.latitude,
    this.longitude,
  });

  factory KhachHangChuaMuaModel.fromJson(Map<String, dynamic> j) =>
      KhachHangChuaMuaModel(
        khachHangId:      j['khachHangId'] as int,
        maKhachHang:      j['maKhachHang'] ?? '',
        tenKhachHang:     j['tenKhachHang'] ?? '',
        soDienThoai:      j['soDienThoai'] as String?,
        diaChi:           j['diaChi'] as String?,
        ngayMuaCuoiCung:  j['ngayMuaCuoiCung'] != null
            ? DateTime.tryParse(j['ngayMuaCuoiCung'] as String)
            : null,
        soNgayChuaMua:    j['soNgayChuaMua'] as int?,
        latitude:         (j['latitude'] as num?)?.toDouble(),
        longitude:        (j['longitude'] as num?)?.toDouble(),
      );
}

class TongQuanDashboard {
  final DateTime tuNgay;
  final DateTime denNgay;
  final double tongDoanhThu;
  final double tongTienNop;
  final double tongTienNo;
  final double tongCongNoHienTai;
  final int soChuyenXe;
  final List<BinhBanItem> binhBanTheoMatHang;
  final List<DaiLyItem> binhBanTheoDaiLy;

  TongQuanDashboard({
    required this.tuNgay,
    required this.denNgay,
    required this.tongDoanhThu,
    required this.tongTienNop,
    required this.tongTienNo,
    required this.tongCongNoHienTai,
    required this.soChuyenXe,
    required this.binhBanTheoMatHang,
    required this.binhBanTheoDaiLy,
  });

  factory TongQuanDashboard.fromJson(Map<String, dynamic> j) => TongQuanDashboard(
        tuNgay:           DateTime.parse(j['tuNgay']),
        denNgay:          DateTime.parse(j['denNgay']),
        tongDoanhThu:     (j['tongDoanhThu'] as num).toDouble(),
        tongTienNop:      (j['tongTienNop'] as num).toDouble(),
        tongTienNo:       (j['tongTienNo'] as num).toDouble(),
        tongCongNoHienTai: (j['tongCongNoHienTai'] as num).toDouble(),
        soChuyenXe:       (j['soChuyenXe'] as num).toInt(),
        binhBanTheoMatHang: (j['binhBanTheoMatHang'] as List)
            .map((e) => BinhBanItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        binhBanTheoDaiLy: (j['binhBanTheoDaiLy'] as List)
            .map((e) => DaiLyItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
