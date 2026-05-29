// lib/features/nhan_vien/data/models/nhan_vien_model.dart

class NhanVienModel {
  final int id;
  final String maNhanVien;
  final String hoTen;
  final String? chucVu;
  final String? soDienThoai;
  final String? email;
  final DateTime? ngaySinh;
  final bool isActive;
  final DateTime createdAt;

  const NhanVienModel({
    required this.id,
    required this.maNhanVien,
    required this.hoTen,
    this.chucVu,
    this.soDienThoai,
    this.email,
    this.ngaySinh,
    required this.isActive,
    required this.createdAt,
  });

  factory NhanVienModel.fromJson(Map<String, dynamic> json) => NhanVienModel(
        id:          json['id'] as int,
        maNhanVien:  json['maNhanVien'] as String? ?? '',
        hoTen:       json['hoTen'] as String? ?? '',
        chucVu:      json['chucVu'] as String?,
        soDienThoai: json['soDienThoai'] as String?,
        email:       json['email'] as String?,
        ngaySinh:    json['ngaySinh'] != null
            ? DateTime.tryParse(json['ngaySinh'] as String)
            : null,
        isActive:    json['isActive'] as bool? ?? true,
        createdAt:   json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
