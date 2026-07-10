// lib/features/thong_bao/presentation/screens/thong_bao_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../data/models/thong_bao_model.dart';
import '../providers/thong_bao_provider.dart';

class ThongBaoDetailScreen extends ConsumerWidget {
  const ThongBaoDetailScreen({super.key, required this.thongBaoId});

  final String thongBaoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idInt      = int.tryParse(thongBaoId) ?? 0;
    final detailAsync = ref.watch(thongBaoDetailProvider(idInt));

    // Auto mark-as-read khi load xong + invalidate badge
    ref.listen(thongBaoDetailProvider(idInt), (_, next) {
      if (next.hasValue && !next.value!.daDoc) {
        ref.read(thongBaoRepositoryProvider).markAsRead(idInt);
        ref.invalidate(soChuaDocProvider);
        ref.invalidate(thongBaoListProvider);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết thông báo')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (_, __) => const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.notifications_none, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('Không tìm thấy thông báo'),
          ]),
        ),
        data: (item) => _DetailBody(item: item),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ThongBaoModel item;
  const _DetailBody({required this.item});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.iconFilled, color: const Color(0xFF00897B), size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.loaiLabel,
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00897B).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item.daDoc ? 'Đã đọc' : 'Chưa đọc',
                                style: TextStyle(
                                  color: item.daDoc ? Colors.grey : const Color(0xFF00897B),
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(item.tieuDe,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(fmt.format(item.createdAt.toLocal()),
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Nội dung
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nội dung',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text(
                    item.noiDung.isNotEmpty ? item.noiDung : '(Không có nội dung)',
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
          ),

          // Nút xem chuyến xe (khi thông báo gắn với một chuyến xe cụ thể)
          if (item.lienQuanChuyenXe && item.refId != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.chuyenXeDetail(item.refId.toString())),
                icon: const Icon(Icons.local_shipping_rounded),
                label: const Text('Xem chuyến xe'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
