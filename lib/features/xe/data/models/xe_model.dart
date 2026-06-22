// lib/features/xe/data/models/xe_model.dart

class XeModel {
  final int id;
  final String bienSoXe;
  final String loaiXe;
  final int? namSanXuat;
  final String trangThai;
  final int? nhanVienLaiXeId;
  final bool isActive;
  final DateTime createdAt;

  const XeModel({
    required this.id,
    required this.bienSoXe,
    required this.loaiXe,
    this.namSanXuat,
    required this.trangThai,
    this.nhanVienLaiXeId,
    required this.isActive,
    required this.createdAt,
  });

  factory XeModel.fromJson(Map<String, dynamic> json) => XeModel(
        id:               json['id'] as int,
        bienSoXe:         json['bienSoXe'] as String? ?? '',
        loaiXe:           json['loaiXe'] as String? ?? '',
        namSanXuat:       json['namSanXuat'] as int?,
        trangThai:        json['trangThai'] as String? ?? 'active',
        nhanVienLaiXeId:  json['nhanVienLaiXeId'] as int?,
        isActive:         json['isActive'] as bool? ?? true,
        createdAt:        json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  String get trangThaiLabel => switch (trangThai.toLowerCase()) {
        'active'      => 'Hoạt động',
        'maintenance' => 'Bảo dưỡng',
        'inactive'    => 'Ngừng hoạt động',
        _             => trangThai,
      };
}
