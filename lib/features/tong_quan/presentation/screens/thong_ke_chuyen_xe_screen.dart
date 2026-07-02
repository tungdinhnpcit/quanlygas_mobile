// lib/features/tong_quan/presentation/screens/thong_ke_chuyen_xe_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../chuyen_xe/data/models/chuyen_xe_model.dart';
import '../providers/tong_quan_provider.dart';

final _vnd = NumberFormat('#,###', 'vi_VN');
final _num = NumberFormat('#,###');
final _date = DateFormat('dd/MM/yyyy');

class ThongKeChuyenXeScreen extends ConsumerWidget {
  final DateTime? tuNgay;
  final DateTime? denNgay;

  const ThongKeChuyenXeScreen({
    super.key,
    this.tuNgay,
    this.denNgay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final effectiveTuNgay = tuNgay ?? today;
    final effectiveDenNgay = denNgay ?? today;

    final dataAsync = ref.watch(thongKeChuyenXeProvider((effectiveTuNgay, effectiveDenNgay)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyến xe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                '$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(thongKeChuyenXeProvider((effectiveTuNgay, effectiveDenNgay))),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Không có chuyến xe trong khoảng thời gian này',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _ChuyenXeStatCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _ChuyenXeStatCard extends StatelessWidget {
  final ChuyenXeModel item;
  const _ChuyenXeStatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    // Tổng tiền CK từ tất cả tài khoản
    final tongCK = item.tienCKTheoTaiKhoan.fold<double>(0, (s, e) => s + e.tienCK);
    final soTK = item.tienCKTheoTaiKhoan.length;
    final ckLabel = soTK == 0
        ? '0 đ'
        : soTK == 1
            ? '${_vnd.format(tongCK)} đ'
            : '${_vnd.format(tongCK)} đ ($soTK TK)';

    // Badge xác nhận
    final daxn  = item.soKhachDaXacNhan;
    final chuaxn = item.soKhachChuaXacNhan;
    final hasXacNhan = daxn + chuaxn > 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/chuyen-xe/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: mã chuyến + ngày + badge trạng thái
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.maChuyenXe,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  Text(
                    _date.format(item.ngayXuat.toLocal()),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(item.trangThai).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.trangThaiLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: _getStatusColor(item.trangThai),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 12),
              _Row2Col(
                label1: 'Xe',
                value1: item.bienSoXe ?? '—',
                label2: 'Lái xe',
                value2: item.tenNhanVien ?? '—',
              ),
              _Row2Col(
                label1: 'Phụ xe',
                value1: item.tenPhuXe ?? '—',
                label2: 'Tổng bình bán',
                value2: '${_num.format(item.tongSoBinhBan)} bình',
              ),
              _Row2Col(
                label1: 'Tổng vỏ',
                value1: '${_num.format(item.tongSoVo)} vỏ',
                label2: 'Nợ',
                value2: item.soTienNo != null && item.soTienNo! > 0
                    ? '${_vnd.format(item.soTienNo)} đ'
                    : '0 đ',
              ),
              _Row2Col(
                label1: 'Tổng tiền thu',
                value1: '${_vnd.format(item.tongTienThu)} đ',
                label2: 'Gas dư',
                value2:
                    '${_vnd.format(item.tongGasDuKg)} kg · ${_vnd.format(item.tienMuaGasDu)} đ',
              ),
              _Row2Col(
                label1: 'Tiền mặt',
                value1: '${_vnd.format(item.tongTienMat)} đ',
                label2: 'Chuyển khoản',
                value2: ckLabel,
              ),
              if (hasXacNhan) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      chuaxn > 0 ? Icons.warning_amber_rounded : Icons.verified_outlined,
                      size: 14,
                      color: chuaxn > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      // hien so khach da xac nhan / tong so khach trong chuyen
                      chuaxn > 0
                          ? 'Đã xác nhận $daxn/${item.tongSoKhachHang} khách'
                          : 'Đã xác nhận ${item.tongSoKhachHang}/${item.tongSoKhachHang} khách',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: chuaxn > 0 ? Colors.orange.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String trangThai) => switch (trangThai) {
        'cho-xuat'   => const Color(0xFF0288D1),
        'dang-giao'  => const Color(0xFF00897B),
        'hoan-thanh' => const Color(0xFF388E3C),
        'huy'        => const Color(0xFFC62828),
        _            => Colors.grey,
      };
}

class _Row2Col extends StatelessWidget {
  final String label1;
  final String value1;
  final String label2;
  final String value2;
  const _Row2Col({
    required this.label1,
    required this.value1,
    required this.label2,
    required this.value2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label1, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label2, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
