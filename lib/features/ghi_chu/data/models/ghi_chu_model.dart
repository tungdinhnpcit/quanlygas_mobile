/// Ghi chú bảo mật cá nhân — mật khẩu được backend mã hoá khi lưu, giải mã khi trả về API.
class GhiChuModel {
  final int? id;          // null khi tạo mới
  final String tieuDe;
  final String taiKhoan;
  final String matKhau;   // plaintext trong bộ nhớ (BE đã giải mã trước khi trả về)
  final String ghiChu;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GhiChuModel({
    this.id,
    required this.tieuDe,
    this.taiKhoan = '',
    this.matKhau = '',
    this.ghiChu = '',
    this.createdAt,
    this.updatedAt,
  });

  factory GhiChuModel.fromJson(Map<String, dynamic> json) => GhiChuModel(
        id: json['id'] as int?,
        tieuDe: (json['tieuDe'] as String?) ?? '',
        taiKhoan: (json['taiKhoan'] as String?) ?? '',
        matKhau: (json['matKhau'] as String?) ?? '',
        ghiChu: (json['ghiChu'] as String?) ?? '',
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
        updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
      );

  GhiChuModel copyWith({
    int? id,
    String? tieuDe,
    String? taiKhoan,
    String? matKhau,
    String? ghiChu,
  }) =>
      GhiChuModel(
        id: id ?? this.id,
        tieuDe: tieuDe ?? this.tieuDe,
        taiKhoan: taiKhoan ?? this.taiKhoan,
        matKhau: matKhau ?? this.matKhau,
        ghiChu: ghiChu ?? this.ghiChu,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}