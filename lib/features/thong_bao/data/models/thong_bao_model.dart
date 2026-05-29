// lib/features/thong_bao/data/models/thong_bao_model.dart

class ThongBaoModel {
  final String id;
  final String type;       // email | sms | push | web
  final String subject;
  final String content;
  final String status;     // pending | sent | failed
  final DateTime createdAt;
  final bool isRead;

  const ThongBaoModel({
    required this.id,
    required this.type,
    required this.subject,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.isRead,
  });

  factory ThongBaoModel.fromJson(Map<String, dynamic> json) => ThongBaoModel(
        id:        json['id']?.toString() ?? '',
        type:      json['type'] as String? ?? 'push',
        subject:   json['subject'] as String? ??
                   json['title'] as String? ?? '(Không có tiêu đề)',
        content:   json['content'] as String? ??
                   json['body'] as String? ??
                   json['message'] as String? ?? '',
        status:    json['status'] as String? ?? 'sent',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : json['timestamp'] != null
                ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
                : DateTime.now(),
        isRead: json['isRead'] as bool? ??
                json['read'] as bool? ?? false,
      );

  String get typeLabel => switch (type.toLowerCase()) {
        'email' => 'Email',
        'sms'   => 'SMS',
        'push'  => 'Thông báo đẩy',
        'web'   => 'Web',
        _       => type,
      };

  String get statusLabel => switch (status.toLowerCase()) {
        'pending' => 'Chờ gửi',
        'sent'    => 'Đã gửi',
        'failed'  => 'Lỗi',
        _         => status,
      };
}
