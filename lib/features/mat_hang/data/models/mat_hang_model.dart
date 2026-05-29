// lib/features/mat_hang/data/models/mat_hang_model.dart

class MatHangModel {
  final int id;
  final String maMatHang;
  final String tenMatHang;
  final String? donViTinh;
  final double giaBan;
  final String? moTa;
  final bool isActive;
  final DateTime createdAt;

  const MatHangModel({
    required this.id,
    required this.maMatHang,
    required this.tenMatHang,
    this.donViTinh,
    required this.giaBan,
    this.moTa,
    required this.isActive,
    required this.createdAt,
  });

  factory MatHangModel.fromJson(Map<String, dynamic> json) => MatHangModel(
        id:         json['id'] as int,
        maMatHang:  json['maMatHang'] as String? ?? '',
        tenMatHang: json['tenMatHang'] as String? ?? '',
        donViTinh:  json['donViTinh'] as String?,
        giaBan:     (json['giaBan'] as num?)?.toDouble() ?? 0,
        moTa:       json['moTa'] as String?,
        isActive:   json['isActive'] as bool? ?? true,
        createdAt:  json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
