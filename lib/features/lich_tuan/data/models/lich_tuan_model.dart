// lib/features/lich_tuan/data/models/lich_tuan_model.dart
import '../../domain/entities/lich_tuan_entity.dart';

class LichTuanModel {
  const LichTuanModel({
    required this.lichtuanId,
    required this.ngayGioBD,
    required this.gio,
    required this.thoiGian,
    required this.diaDiem,
    required this.chuTri,
    required this.noiDung,
    required this.ngayGioBDBase,
    required this.ngayGioKTBase,
    required this.thamGiaChitiet,
    required this.thayDoi,
    required this.isTruyenHinh,
    required this.tt,
  });

  final int lichtuanId;
  final String ngayGioBD;
  final String gio;
  final String thoiGian;
  final String diaDiem;
  final String chuTri;
  final String noiDung;
  final DateTime ngayGioBDBase;
  final DateTime ngayGioKTBase;
  final String thamGiaChitiet;
  final String thayDoi;
  final bool isTruyenHinh;
  final String tt;

  factory LichTuanModel.fromJson(Map<String, dynamic> json) {
    return LichTuanModel(
      lichtuanId: json['Lichtuan_ID'] as int,
      ngayGioBD: json['NgayGioBD'] as String? ?? '',
      gio: json['gio'] as String? ?? '',
      thoiGian: json['ThoiGian'] as String? ?? '',
      diaDiem: json['DiaDiem'] as String? ?? '',
      chuTri: json['ChuTri'] as String? ?? '',
      noiDung: json['NoiDung'] as String? ?? '',
      ngayGioBDBase: DateTime.parse(json['NgayGioBD_Base'] as String),
      ngayGioKTBase: DateTime.parse(json['NgayGioKT_Base'] as String),
      thamGiaChitiet: json['ThamGiaChitiet'] as String? ?? '',
      thayDoi: json['ThayDoi'] as String? ?? '',
      isTruyenHinh: json['isTruyenHinh'] as bool? ?? false,
      tt: json['TT'] as String? ?? '',
    );
  }

  LichTuanEntity toEntity() => LichTuanEntity(
        lichtuanId: lichtuanId,
        ngayGioBD: ngayGioBD,
        gio: gio,
        thoiGian: thoiGian,
        diaDiem: diaDiem,
        chuTri: chuTri,
        noiDung: noiDung,
        ngayGioBDBase: ngayGioBDBase,
        ngayGioKTBase: ngayGioKTBase,
        thamGiaChitiet: thamGiaChitiet,
        thayDoi: thayDoi,
        isTruyenHinh: isTruyenHinh,
        tt: tt,
      );
}
