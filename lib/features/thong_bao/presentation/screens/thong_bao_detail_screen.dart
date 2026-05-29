// lib/features/thong_bao/presentation/screens/thong_bao_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/thong_bao_model.dart';
import '../providers/thong_bao_provider.dart';

class ThongBaoDetailScreen extends ConsumerWidget {
  const ThongBaoDetailScreen({super.key, required this.thongBaoId});

  final String thongBaoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(thongBaoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết thông báo')),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Không tải được thông báo')),
        data: (list) {
          final item = list.where((n) => n.id == thongBaoId).firstOrNull;
          if (item == null) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Không tìm thấy thông báo'),
                ],
              ),
            );
          }
          return _DetailBody(item: item);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ThongBaoModel item;
  const _DetailBody({required this.item});

  IconData _typeIcon(String type) => switch (type.toLowerCase()) {
        'email' => Icons.email_rounded,
        'sms'   => Icons.sms_rounded,
        'push'  => Icons.notifications_rounded,
        'web'   => Icons.web_rounded,
        _       => Icons.notifications_rounded,
      };

  Color _statusColor(String status) => switch (status.toLowerCase()) {
        'sent'    => const Color(0xFF10B981),
        'pending' => const Color(0xFFF59E0B),
        'failed'  => const Color(0xFFEF4444),
        _         => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final fmt         = DateFormat('dd/MM/yyyy HH:mm');
    final statusColor = _statusColor(item.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_typeIcon(item.type),
                            color: const Color(0xFF00897B), size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.typeLabel,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    item.statusLabel,
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (!item.isRead) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00897B)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Chưa đọc',
                                      style: TextStyle(
                                          color: Color(0xFF00897B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(
                    item.subject,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        fmt.format(item.createdAt.toLocal()),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nội dung',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text(
                    item.content.isNotEmpty ? item.content : '(Không có nội dung)',
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
