// lib/features/lich_tuan/domain/entities/lich_tuan_entity.dart
import 'package:equatable/equatable.dart';

class LichTuanEntity extends Equatable {
  const LichTuanEntity({
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

  @override
  List<Object?> get props => [lichtuanId];
}
