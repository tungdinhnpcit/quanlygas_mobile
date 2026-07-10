// lib/features/thong_bao/data/models/thong_bao_model.dart
import 'package:flutter/material.dart';

class ThongBaoModel {
  final int id;
  final String tieuDe;
  final String noiDung;
  /// CHUYEN_MOI | DUYET_CHUYEN_XE | CAP_NHAT_CHUYEN | LICH_TUAN | THONG_BAO
  final String loai;
  /// chuyen_xe.id nếu loai liên quan đến chuyến xe
  final int? refId;
  final bool daDoc;
  final DateTime createdAt;

  const ThongBaoModel({
    required this.id,
    required this.tieuDe,
    required this.noiDung,
    required this.loai,
    this.refId,
    required this.daDoc,
    required this.createdAt,
  });

  factory ThongBaoModel.fromJson(Map<String, dynamic> json) => ThongBaoModel(
        id:        (json['id'] as num).toInt(),
        tieuDe:    json['tieuDe'] as String? ?? '(Không có tiêu đề)',
        noiDung:   json['noiDung'] as String? ?? '',
        loai:      json['loai'] as String? ?? 'THONG_BAO',
        refId:     json['refId'] != null ? (json['refId'] as num).toInt() : null,
        daDoc:     json['daDoc'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );

  /// Thông báo có gắn với một chuyến xe cụ thể (dùng để hiện nút "Xem chuyến xe")
  bool get lienQuanChuyenXe =>
      loai == 'CHUYEN_MOI' || loai == 'DUYET_CHUYEN_XE' || loai == 'CAP_NHAT_CHUYEN';

  IconData get icon {
    switch (loai) {
      case 'CHUYEN_MOI':
        return Icons.local_shipping_outlined;
      case 'DUYET_CHUYEN_XE':
        return Icons.check_circle_outline;
      case 'CAP_NHAT_CHUYEN':
        return Icons.edit_note_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  IconData get iconFilled {
    switch (loai) {
      case 'CHUYEN_MOI':
        return Icons.local_shipping_rounded;
      case 'DUYET_CHUYEN_XE':
        return Icons.check_circle_rounded;
      case 'CAP_NHAT_CHUYEN':
        return Icons.edit_note_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  String get loaiLabel {
    switch (loai) {
      case 'CHUYEN_MOI':
        return 'Chuyến xe mới';
      case 'DUYET_CHUYEN_XE':
        return 'Chuyến xe đã duyệt';
      case 'CAP_NHAT_CHUYEN':
        return 'Cập nhật chuyến';
      default:
        return 'Thông báo';
    }
  }

  ThongBaoModel copyWith({bool? daDoc}) => ThongBaoModel(
        id:        id,
        tieuDe:    tieuDe,
        noiDung:   noiDung,
        loai:      loai,
        refId:     refId,
        daDoc:     daDoc ?? this.daDoc,
        createdAt: createdAt,
      );
}
