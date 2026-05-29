// lib/features/nha_cung_cap/data/models/nha_cung_cap_model.dart

class NhaCungCapModel {
  final int id;
  final String maNCC;
  final String tenNCC;
  final String? diaChi;
  final String? soDienThoai;
  final String? email;
  final String? nguoiLienHe;
  final bool isActive;
  final DateTime createdAt;

  const NhaCungCapModel({
    required this.id,
    required this.maNCC,
    required this.tenNCC,
    this.diaChi,
    this.soDienThoai,
    this.email,
    this.nguoiLienHe,
    required this.isActive,
    required this.createdAt,
  });

  factory NhaCungCapModel.fromJson(Map<String, dynamic> json) => NhaCungCapModel(
        id:          json['id'] as int,
        maNCC:       json['maNCC'] as String? ?? '',
        tenNCC:      json['tenNCC'] as String? ?? '',
        diaChi:      json['diaChi'] as String?,
        soDienThoai: json['soDienThoai'] as String?,
        email:       json['email'] as String?,
        nguoiLienHe: json['nguoiLienHe'] as String?,
        isActive:    json['isActive'] as bool? ?? true,
        createdAt:   json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
