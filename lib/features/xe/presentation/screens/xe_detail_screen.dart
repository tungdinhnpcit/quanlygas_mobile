// lib/features/xe/presentation/screens/xe_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/xe_provider.dart';

class XeDetailScreen extends ConsumerWidget {
  const XeDetailScreen({super.key, required this.xeId});
  final int xeId;

  Color _trangThaiColor(String tt) => switch (tt.toLowerCase()) {
        'active'      => const Color(0xFF10B981),
        'maintenance' => const Color(0xFFF59E0B),
        'inactive'    => const Color(0xFFEF4444),
        _             => Colors.grey,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(xeDetailProvider(xeId));
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết xe')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Không tải được thông tin')),
        data: (xe) {
          final tColor = _trangThaiColor(xe.trangThai);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00897B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.local_shipping_rounded,
                              color: Color(0xFF00897B), size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(xe.bienSoXe,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.w700)),
                              Text(xe.loaiXe,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  xe.trangThaiLabel,
                                  style: TextStyle(
                                      color: tColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thông tin xe',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey)),
                        const Divider(height: 16),
                        _InfoRow(Icons.calendar_today_outlined, 'Năm sản xuất',
                            xe.namSanXuat?.toString() ?? '—'),
                        _InfoRow(Icons.person_outline, 'Lái xe ID',
                            xe.nhanVienLaiXeId?.toString() ?? '—'),
                        _InfoRow(
                          xe.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                          'Trạng thái hoạt động',
                          xe.isActive ? 'Đang hoạt động' : 'Ngừng hoạt động',
                        ),
                        _InfoRow(Icons.access_time_outlined, 'Ngày tạo',
                            DateFormat('dd/MM/yyyy').format(xe.createdAt.toLocal())),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
