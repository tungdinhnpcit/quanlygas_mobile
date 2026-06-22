// lib/features/thong_bao/data/models/thong_bao_model.dart
import 'package:flutter/material.dart';

class ThongBaoModel {
  final int id;
  final String tieuDe;
  final String noiDung;
  /// CHUYEN_MOI | THONG_BAO
  final String loai;
  /// chuyen_xe.id nếu loai = CHUYEN_MOI
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

  IconData get icon =>
      loai == 'CHUYEN_MOI' ? Icons.local_shipping_outlined : Icons.notifications_outlined;

  IconData get iconFilled =>
      loai == 'CHUYEN_MOI' ? Icons.local_shipping_rounded : Icons.notifications_rounded;

  String get loaiLabel => loai == 'CHUYEN_MOI' ? 'Chuyến xe mới' : 'Thông báo';

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
