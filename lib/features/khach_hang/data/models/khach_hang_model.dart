// lib/features/khach_hang/data/models/khach_hang_model.dart

class KhachHangModel {
  final int id;
  final String maKhachHang;
  final String tenKhachHang;
  final String? diaChi;
  final String? soDienThoai;
  final String? email;
  final double? latitude;
  final double? longitude;
  final String? anhCuaHang;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const KhachHangModel({
    required this.id,
    required this.maKhachHang,
    required this.tenKhachHang,
    this.diaChi,
    this.soDienThoai,
    this.email,
    this.latitude,
    this.longitude,
    this.anhCuaHang,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory KhachHangModel.fromJson(Map<String, dynamic> json) => KhachHangModel(
        id:            json['id'] as int,
        maKhachHang:   json['maKhachHang'] as String? ?? '',
        tenKhachHang:  json['tenKhachHang'] as String? ?? '',
        diaChi:        json['diaChi'] as String?,
        soDienThoai:   json['soDienThoai'] as String?,
        email:         json['email'] as String?,
        latitude:      (json['latitude'] as num?)?.toDouble(),
        longitude:     (json['longitude'] as num?)?.toDouble(),
        anhCuaHang:    json['anhCuaHang'] as String?,
        isActive:      json['isActive'] as bool? ?? true,
        createdAt:     json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        updatedAt:     json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
      );
}
