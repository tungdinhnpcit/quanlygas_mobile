// lib/features/mat_hang/presentation/screens/mat_hang_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/mat_hang_provider.dart';

class MatHangDetailScreen extends ConsumerWidget {
  const MatHangDetailScreen({super.key, required this.matHangId});
  final int matHangId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async   = ref.watch(matHangDetailProvider(matHangId));
    final fmtCurr = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết mặt hàng')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Không tải được thông tin')),
        data: (mh) {
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
                          child: const Icon(Icons.inventory_2_rounded,
                              color: Color(0xFF00897B), size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mh.maMatHang,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(mh.tenMatHang,
                                  style: const TextStyle(
                                      fontSize: 17, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text(
                                fmtCurr.format(mh.giaBan),
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00897B)),
                              ),
                              if (mh.donViTinh != null)
                                Text('/ ${mh.donViTinh}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                        const Text('Thông tin chi tiết',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey)),
                        const Divider(height: 16),
                        _InfoRow(Icons.straighten_outlined, 'Đơn vị tính',
                            mh.donViTinh ?? '—'),
                        _InfoRow(
                          mh.isActive ? Icons.check_circle_outline : Icons.cancel_outlined,
                          'Kinh doanh',
                          mh.isActive ? 'Đang kinh doanh' : 'Ngừng kinh doanh',
                        ),
                        _InfoRow(Icons.access_time_outlined, 'Ngày tạo',
                            DateFormat('dd/MM/yyyy').format(mh.createdAt.toLocal())),
                      ],
                    ),
                  ),
                ),
                if (mh.moTa != null && mh.moTa!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Mô tả',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(mh.moTa!,
                              style: const TextStyle(fontSize: 14, height: 1.6)),
                        ],
                      ),
                    ),
                  ),
                ],
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
