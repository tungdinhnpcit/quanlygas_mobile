// lib/features/nhan_vien/presentation/screens/nhan_vien_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/nhan_vien_provider.dart';

class NhanVienDetailScreen extends ConsumerWidget {
  const NhanVienDetailScreen({super.key, required this.nhanVienId});
  final int nhanVienId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nhanVienDetailProvider(nhanVienId));
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết nhân viên')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Không tải được thông tin')),
        data: (nv) {
          final fmtDate = DateFormat('dd/MM/yyyy');
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
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.15),
                          child: Text(
                            nv.hoTen.isNotEmpty ? nv.hoTen[0].toUpperCase() : 'N',
                            style: const TextStyle(
                                color: Color(0xFF00897B),
                                fontWeight: FontWeight.bold,
                                fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nv.maNhanVien,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(nv.hoTen,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.w700)),
                              if (nv.chucVu != null)
                                Text(nv.chucVu!,
                                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (nv.isActive
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  nv.isActive ? 'Đang làm việc' : 'Nghỉ việc',
                                  style: TextStyle(
                                    color: nv.isActive
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
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
                        const Text('Thông tin liên hệ',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey)),
                        const Divider(height: 16),
                        _InfoRow(Icons.phone_outlined, 'Điện thoại', nv.soDienThoai ?? '—'),
                        _InfoRow(Icons.email_outlined, 'Email', nv.email ?? '—'),
                        _InfoRow(Icons.cake_outlined, 'Ngày sinh',
                            nv.ngaySinh != null ? fmtDate.format(nv.ngaySinh!.toLocal()) : '—'),
                        _InfoRow(Icons.access_time_outlined, 'Ngày tạo',
                            DateFormat('dd/MM/yyyy').format(nv.createdAt.toLocal())),
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
