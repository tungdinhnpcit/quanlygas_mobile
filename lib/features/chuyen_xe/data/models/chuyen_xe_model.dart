// lib/features/chuyen_xe/data/models/chuyen_xe_model.dart
import 'package:flutter/material.dart';

// ---------- Ảnh giao hàng ----------

class AnhChuyenXeModel {
  final int id;
  final String url;
  final DateTime uploadedAt;

  const AnhChuyenXeModel({
    required this.id,
    required this.url,
    required this.uploadedAt,
  });

  factory AnhChuyenXeModel.fromJson(Map<String, dynamic> json) => AnhChuyenXeModel(
        id:         json['id'] as int,
        url:        json['url'] as String,
        uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

// ---------- Xác nhận khách hàng ----------

class XacNhanKhachHangModel {
  final int id;
  final int khachHangId;
  final String? tenKhachHang;
  final String? loaiXacNhan;  // 'anh' | 'ky' | null
  final String? url;
  final DateTime? ngayXacNhan;

  const XacNhanKhachHangModel({
    required this.id,
    required this.khachHangId,
    this.tenKhachHang,
    this.loaiXacNhan,
    this.url,
    this.ngayXacNhan,
  });

  factory XacNhanKhachHangModel.fromJson(Map<String, dynamic> json) => XacNhanKhachHangModel(
        id:             json['id'] as int,
        khachHangId:    json['khachHangId'] as int,
        tenKhachHang:   json['tenKhachHang'] as String?,
        loaiXacNhan:    json['loaiXacNhan'] as String?,
        url:            json['url'] as String?,
        ngayXacNhan:    DateTime.tryParse(json['ngayXacNhan'] as String? ?? ''),
      );

  bool get daXacNhan => url != null && url!.isNotEmpty;
}

// ---------- Tổng tiền chuyển khoản theo tài khoản (aggregate card tổng quan) ----------

class TienCKTaiKhoanModel {
  final String? tenTaiKhoan;
  final double tienCK;

  const TienCKTaiKhoanModel({this.tenTaiKhoan, required this.tienCK});

  factory TienCKTaiKhoanModel.fromJson(Map<String, dynamic> json) => TienCKTaiKhoanModel(
        tenTaiKhoan: json['tenTaiKhoan'] as String?,
        tienCK:      (json['tienCK'] as num? ?? 0).toDouble(),
      );
}

// ---------- Bán hàng lái xe nhập (mobile) ----------

class BanHangKhachHangModel {
  final int id;
  final int khachHangId;
  final String? tenKhachHang;
  final int matHangId;
  final String? maMatHang;
  final String? tenMatHang;
  final String? maNhaCungCap;
  final String? tenNhaCungCap;
  final String? donViTinh;
  final int soLuong;
  final double donGia;
  final double thanhTien;
  final int soVoBan;
  final int soVoThu;
  final double tienMat;
  final double tienCK;
  final int? taiKhoanCKId;       // id tai khoan ngan hang nhan chuyen khoan
  final String? tenTaiKhoanCK;   // ten tai khoan hien thi (tu nav TaiKhoanCK)
  final int? xacNhanId;
  final String? ghiChu;
  final DateTime createdAt;

  const BanHangKhachHangModel({
    required this.id,
    required this.khachHangId,
    this.tenKhachHang,
    required this.matHangId,
    this.maMatHang,
    this.tenMatHang,
    this.maNhaCungCap,
    this.tenNhaCungCap,
    this.donViTinh,
    required this.soLuong,
    required this.donGia,
    required this.thanhTien,
    required this.soVoBan,
    required this.soVoThu,
    this.tienMat = 0,
    this.tienCK = 0,
    this.taiKhoanCKId,
    this.tenTaiKhoanCK,
    this.xacNhanId,
    this.ghiChu,
    required this.createdAt,
  });

  factory BanHangKhachHangModel.fromJson(Map<String, dynamic> json) =>
      BanHangKhachHangModel(
        id:             json['id'] as int,
        khachHangId:    json['khachHangId'] as int,
        tenKhachHang:   json['tenKhachHang'] as String?,
        matHangId:      json['matHangId'] as int,
        maMatHang:      json['maMatHang'] as String?,
        tenMatHang:     json['tenMatHang'] as String?,
        maNhaCungCap:   json['maNhaCungCap'] as String?,
        tenNhaCungCap:  json['tenNhaCungCap'] as String?,
        donViTinh:      json['donViTinh'] as String?,
        soLuong:        json['soLuong'] as int,
        donGia:         (json['donGia'] as num).toDouble(),
        thanhTien:      (json['thanhTien'] as num).toDouble(),
        soVoBan:        json['soVoBan'] as int? ?? 0,
        soVoThu:        json['soVoThu'] as int? ?? 0,
        tienMat:        (json['tienMat'] as num? ?? 0).toDouble(),
        tienCK:         (json['tienCK']  as num? ?? 0).toDouble(),
        taiKhoanCKId:   json['taiKhoanCKId'] as int?,
        tenTaiKhoanCK:  json['tenTaiKhoanCK'] as String?,
        xacNhanId:      json['xacNhanId'] as int?,
        ghiChu:         json['ghiChu'] as String?,
        createdAt:      DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

// ---------- Chi tiết hàng trong chuyến ----------

class ChuyenXeChiTietModel {
  final int id;
  final int khachHangId;
  final String? tenKhachHang;
  final int matHangId;
  final String? tenMatHang;
  final String? tenNhaCungCap;
  final int soLuong;
  final double donGia;
  final double thanhTien;
  final int soVoBan;
  final int soVoThu;

  const ChuyenXeChiTietModel({
    required this.id,
    required this.khachHangId,
    this.tenKhachHang,
    required this.matHangId,
    this.tenMatHang,
    this.tenNhaCungCap,
    required this.soLuong,
    required this.donGia,
    required this.thanhTien,
    required this.soVoBan,
    required this.soVoThu,
  });

  factory ChuyenXeChiTietModel.fromJson(Map<String, dynamic> json) => ChuyenXeChiTietModel(
        id:             json['id'] as int,
        khachHangId:    json['khachHangId'] as int? ?? 0,
        tenKhachHang:   json['tenKhachHang'] as String?,
        matHangId:      json['matHangId'] as int,
        tenMatHang:     json['tenMatHang'] as String?,
        tenNhaCungCap:  json['tenNhaCungCap'] as String?,
        soLuong:        json['soLuong'] as int,
        donGia:         (json['donGia'] as num? ?? 0).toDouble(),
        thanhTien:      (json['thanhTien'] as num? ?? 0).toDouble(),
        soVoBan:        json['soVoBan'] as int? ?? 0,
        soVoThu:        json['soVoThu'] as int? ?? 0,
      );
}

// ---------- Kết thúc chuyến: Thu vỏ bình ----------

class VoThuChiTietModel {
  final int id;
  final int? nhaCungCapId;
  final String? maNhaCungCap;
  final String? tenNhaCungCap;
  final int matHangId;
  final String? maMatHang;
  final String? tenMatHang;
  final int soVo;

  const VoThuChiTietModel({
    required this.id,
    this.nhaCungCapId,
    this.maNhaCungCap,
    this.tenNhaCungCap,
    required this.matHangId,
    this.maMatHang,
    this.tenMatHang,
    required this.soVo,
  });

  factory VoThuChiTietModel.fromJson(Map<String, dynamic> json) => VoThuChiTietModel(
        id:             json['id'] as int? ?? 0,
        nhaCungCapId:   json['nhaCungCapId'] as int?,
        maNhaCungCap:   json['maNhaCungCap'] as String?,
        tenNhaCungCap:  json['tenNhaCungCap'] as String?,
        matHangId:      json['matHangId'] as int,
        maMatHang:      json['maMatHang'] as String?,
        tenMatHang:     json['tenMatHang'] as String?,
        soVo:           json['soVo'] as int,
      );

  /// Nhãn "MA - Tên".
  String get matHangLabel =>
      [maMatHang, tenMatHang].where((s) => s != null && s.isNotEmpty).join(' - ');
  String get nhaCungCapLabel =>
      [maNhaCungCap, tenNhaCungCap].where((s) => s != null && s.isNotEmpty).join(' - ');
}

// ---------- Kết thúc chuyến: Mua gas dư từ khách hàng ----------

class GasDuChiTietModel {
  final int id;
  final int khachHangId;
  final String? tenKhachHang;
  final int matHangId;
  final String? tenMatHang;
  final double soKg;
  final double donGia;
  final double thanhTien;

  const GasDuChiTietModel({
    required this.id,
    required this.khachHangId,
    this.tenKhachHang,
    required this.matHangId,
    this.tenMatHang,
    required this.soKg,
    required this.donGia,
    required this.thanhTien,
  });

  factory GasDuChiTietModel.fromJson(Map<String, dynamic> json) => GasDuChiTietModel(
        id:           json['id'] as int,
        khachHangId:  json['khachHangId'] as int,
        tenKhachHang: json['tenKhachHang'] as String?,
        matHangId:    json['matHangId'] as int,
        tenMatHang:   json['tenMatHang'] as String?,
        soKg:         (json['soKg'] as num).toDouble(),
        donGia:       (json['donGia'] as num).toDouble(),
        thanhTien:    (json['thanhTien'] as num).toDouble(),
      );
}

// ---------- Kết thúc chuyến: Thu nợ cũ ----------

class TraNoCuModel {
  final int id;
  final int khachHangId;
  final String? tenKhachHang;
  final double soTien;
  final String? ghiChu;

  const TraNoCuModel({
    required this.id,
    required this.khachHangId,
    this.tenKhachHang,
    required this.soTien,
    this.ghiChu,
  });

  factory TraNoCuModel.fromJson(Map<String, dynamic> json) => TraNoCuModel(
        id:           json['id'] as int,
        khachHangId:  json['khachHangId'] as int,
        tenKhachHang: json['tenKhachHang'] as String?,
        soTien:       (json['soTien'] as num).toDouble(),
        ghiChu:       json['ghiChu'] as String?,
      );
}

// ---------- Kết thúc chuyến: Chi tiết từng khách hàng mua ----------

class KetThucChiTietModel {
  final int id;
  final int khachHangId;
  final String? tenKhachHang;
  final int matHangId;
  final String? tenMatHang;
  final int soLuong;
  final double donGia;
  final double thanhTien;
  final int soVoBan;
  final int soVoThu;
  final String? loaiVo;

  const KetThucChiTietModel({
    required this.id,
    required this.khachHangId,
    this.tenKhachHang,
    required this.matHangId,
    this.tenMatHang,
    required this.soLuong,
    required this.donGia,
    required this.thanhTien,
    required this.soVoBan,
    required this.soVoThu,
    this.loaiVo,
  });

  factory KetThucChiTietModel.fromJson(Map<String, dynamic> json) => KetThucChiTietModel(
        id:           json['id'] as int? ?? 0,
        khachHangId:  json['khachHangId'] as int? ?? 0,
        tenKhachHang: json['tenKhachHang'] as String?,
        matHangId:    json['matHangId'] as int? ?? 0,
        tenMatHang:   json['tenMatHang'] as String?,
        soLuong:      json['soLuong'] as int? ?? 0,
        donGia:       (json['donGia'] as num? ?? 0).toDouble(),
        thanhTien:    (json['thanhTien'] as num? ?? 0).toDouble(),
        soVoBan:      json['soVoBan'] as int? ?? 0,
        soVoThu:      json['soVoThu'] as int? ?? 0,
        loaiVo:       json['loaiVo'] as String?,
      );
}

// ---------- Kết thúc chuyến: Tổng hợp ----------

class KetThucChuyenXeModel {
  final int id;
  final DateTime? ngayKetThuc;
  final double tienMat;
  final double tienCK;
  final double tongTienNop;
  final double soTienNo;
  final int soVoThuThucTe;
  final double tienUngMuaVo;
  final int soVoMua;
  final double tongTienTraGasDu;
  final double tongThuNoCu;
  final String? ghiChu;
  final List<KetThucChiTietModel> chiTiet;
  final List<VoThuChiTietModel> voThu;
  final List<GasDuChiTietModel> gasDu;
  final List<TraNoCuModel> traNoCu;

  const KetThucChuyenXeModel({
    required this.id,
    this.ngayKetThuc,
    required this.tienMat,
    required this.tienCK,
    required this.tongTienNop,
    required this.soTienNo,
    required this.soVoThuThucTe,
    required this.tienUngMuaVo,
    required this.soVoMua,
    required this.tongTienTraGasDu,
    required this.tongThuNoCu,
    this.ghiChu,
    required this.chiTiet,
    required this.voThu,
    required this.gasDu,
    required this.traNoCu,
  });

  factory KetThucChuyenXeModel.fromJson(Map<String, dynamic> json) => KetThucChuyenXeModel(
        id:               json['id'] as int? ?? 0,
        ngayKetThuc:      json['ngayKetThuc'] != null
            ? DateTime.tryParse(json['ngayKetThuc'] as String)
            : null,
        tienMat:          (json['tienMat'] as num? ?? 0).toDouble(),
        tienCK:           (json['tienCK'] as num? ?? 0).toDouble(),
        tongTienNop:      (json['tongTienNop'] as num? ?? 0).toDouble(),
        soTienNo:         (json['soTienNo'] as num? ?? 0).toDouble(),
        soVoThuThucTe:    json['soVoThuThucTe'] as int? ?? 0,
        tienUngMuaVo:     (json['tienUngMuaVo'] as num? ?? 0).toDouble(),
        soVoMua:          json['soVoMua'] as int? ?? 0,
        tongTienTraGasDu: (json['tongTienTraGasDu'] as num? ?? 0).toDouble(),
        tongThuNoCu:      (json['tongThuNoCu'] as num? ?? 0).toDouble(),
        ghiChu:           json['ghiChu'] as String?,
        chiTiet: (json['chiTiet'] as List? ?? [])
            .map((e) => KetThucChiTietModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        voThu: (json['voThu'] as List? ?? [])
            .map((e) => VoThuChiTietModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        gasDu: (json['gasDu'] as List? ?? [])
            .map((e) => GasDuChiTietModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        traNoCu: (json['traNoCu'] as List? ?? [])
            .map((e) => TraNoCuModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ---------- Chuyến xe (main model) ----------

class ChuyenXeModel {
  final int id;
  final String maChuyenXe;
  final DateTime ngayXuat;
  final int xeId;
  final String? bienSoXe;
  final int nhanVienId;
  final String? tenNhanVien;
  final int? phuXeId;
  final String? tenPhuXe;
  final String trangThai;
  final String loai; // 'web' | 'mobile'
  final double tongTienThu;
  final double? soTienNo;
  final String? ghiChu;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int tongSoBinhBan;
  final int tongSoVo;
  final double tongTienNop;
  final double tongGasDuKg;
  final double tienMuaGasDu;
  final bool hasKetThuc;
  final List<ChuyenXeChiTietModel> chiTiet;
  final List<AnhChuyenXeModel> anh;
  final List<BanHangKhachHangModel> banHang;
  final List<GasDuChiTietModel> banHangGasDu;
  final List<XacNhanKhachHangModel> xacNhan;
  final KetThucChuyenXeModel? ketThuc;
  // Aggregate fields cho card tổng quan (từ list API)
  final double tongTienMat;
  final List<TienCKTaiKhoanModel> tienCKTheoTaiKhoan;
  final int soKhachDaXacNhan;
  final int soKhachChuaXacNhan;
  final int tongSoKhachHang;

  const ChuyenXeModel({
    required this.id,
    required this.maChuyenXe,
    required this.ngayXuat,
    required this.xeId,
    this.bienSoXe,
    required this.nhanVienId,
    this.tenNhanVien,
    this.phuXeId,
    this.tenPhuXe,
    required this.trangThai,
    this.loai = 'web',
    required this.tongTienThu,
    this.soTienNo,
    this.ghiChu,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.tongSoBinhBan = 0,
    this.tongSoVo = 0,
    this.tongTienNop = 0,
    this.tongGasDuKg = 0,
    this.tienMuaGasDu = 0,
    this.hasKetThuc = false,
    required this.chiTiet,
    required this.anh,
    this.banHang = const [],
    this.banHangGasDu = const [],
    this.xacNhan = const [],
    this.ketThuc,
    this.tongTienMat = 0,
    this.tienCKTheoTaiKhoan = const [],
    this.soKhachDaXacNhan = 0,
    this.soKhachChuaXacNhan = 0,
    this.tongSoKhachHang = 0,
  });

  factory ChuyenXeModel.fromJson(Map<String, dynamic> json) => ChuyenXeModel(
        id:            json['id'] as int,
        maChuyenXe:    json['maChuyenXe'] as String,
        ngayXuat:      DateTime.tryParse(json['ngayXuat'] as String? ?? '') ?? DateTime.now(),
        xeId:          json['xeId'] as int,
        bienSoXe:      json['bienSoXe'] as String?,
        nhanVienId:    json['nhanVienId'] as int,
        tenNhanVien:   json['tenNhanVien'] as String?,
        phuXeId:       json['phuXeId'] as int?,
        tenPhuXe:      json['tenPhuXe'] as String?,
        trangThai:     json['trangThai'] as String,
        loai:          json['loai'] as String? ?? 'web',
        tongTienThu:   (json['tongTienThu'] as num).toDouble(),
        soTienNo:      (json['soTienNo'] as num?)?.toDouble(),
        ghiChu:        json['ghiChu'] as String?,
        isActive:      json['isActive'] as bool? ?? true,
        createdAt:     DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        updatedAt:     json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
        tongSoBinhBan: (json['tongSoBinhBan'] as num?)?.toInt() ?? 0,
        tongSoVo:      (json['tongSoVo'] as num?)?.toInt() ?? 0,
        tongTienNop:   (json['tongTienNop'] as num?)?.toDouble() ?? 0,
        tongGasDuKg:   (json['tongGasDuKg'] as num?)?.toDouble() ?? 0,
        tienMuaGasDu:  (json['tienMuaGasDu'] as num?)?.toDouble() ?? 0,
        hasKetThuc:    json['hasKetThuc'] as bool? ?? false,
        chiTiet: (json['chiTiet'] as List? ?? [])
            .map((e) => ChuyenXeChiTietModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        anh: (json['anh'] as List? ?? [])
            .map((e) => AnhChuyenXeModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        banHang: (json['banHang'] as List? ?? [])
            .map((e) => BanHangKhachHangModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        banHangGasDu: (json['banHangGasDu'] as List? ?? [])
            .map((e) => GasDuChiTietModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        xacNhan: (json['xacNhan'] as List? ?? [])
            .map((e) => XacNhanKhachHangModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        ketThuc: json['ketThuc'] != null
            ? KetThucChuyenXeModel.fromJson(json['ketThuc'] as Map<String, dynamic>)
            : null,
        tongTienMat:          (json['tongTienMat'] as num? ?? 0).toDouble(),
        tienCKTheoTaiKhoan:   (json['tienCKTheoTaiKhoan'] as List? ?? [])
            .map((e) => TienCKTaiKhoanModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        soKhachDaXacNhan:     json['soKhachDaXacNhan'] as int? ?? 0,
        soKhachChuaXacNhan:   json['soKhachChuaXacNhan'] as int? ?? 0,
        tongSoKhachHang:      json['tongSoKhachHang'] as int? ?? 0,
      );

  /// Nhãn trạng thái hiển thị tiếng Việt.
  String get trangThaiLabel => switch (trangThai) {
        'cho-xuat'   => 'Chờ xuất',
        'dang-giao'  => 'Đang giao',
        'hoan-thanh' => 'Hoàn thành',
        'huy'        => 'Huỷ',
        _            => trangThai,
      };

  /// Màu badge trạng thái.
  Color get trangThaiColor => switch (trangThai) {
        'cho-xuat'   => const Color(0xFFF59E0B),
        'dang-giao'  => const Color(0xFF3B82F6),
        'hoan-thanh' => const Color(0xFF10B981),
        'huy'        => const Color(0xFFEF4444),
        _            => Colors.grey,
      };

  /// Chuyến đang thực hiện (chưa kết thúc).
  bool get daDangThucHien =>
      trangThai == 'cho-xuat' || trangThai == 'dang-giao';

  /// Chuyến đã kết thúc hoặc bị huỷ.
  bool get daKetThuc =>
      trangThai == 'hoan-thanh' || trangThai == 'huy';
}
