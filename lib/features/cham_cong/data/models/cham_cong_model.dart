// lib/features/cham_cong/data/models/cham_cong_model.dart

class ChamCongModel {
  final int id;
  final int nhanVienId;
  final String tenNhanVien;
  final DateTime ngay;
  final String kyHieu;     // B | H1 | H2 | V | K | O
  final String buoi;       // sang | chieu | ca
  final int? chuyenXeId;
  final int? chuyenLayHangId;
  final String? ghiChu;

  ChamCongModel({
    required this.id,
    required this.nhanVienId,
    required this.tenNhanVien,
    required this.ngay,
    required this.kyHieu,
    required this.buoi,
    this.chuyenXeId,
    this.chuyenLayHangId,
    this.ghiChu,
  });

  factory ChamCongModel.fromJson(Map<String, dynamic> json) {
    return ChamCongModel(
      id: json['id'] as int? ?? 0,
      nhanVienId: json['nhanVienId'] as int? ?? 0,
      tenNhanVien: json['tenNhanVien'] as String? ?? '',
      ngay: DateTime.tryParse(json['ngay'] as String? ?? '') ?? DateTime.now(),
      kyHieu: json['kyHieu'] as String? ?? 'B',
      buoi: json['buoi'] as String? ?? 'ca',
      chuyenXeId: json['chuyenXeId'] as int?,
      chuyenLayHangId: json['chuyenLayHangId'] as int?,
      ghiChu: json['ghiChu'] as String?,
    );
  }
}
