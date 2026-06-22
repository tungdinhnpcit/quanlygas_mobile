// lib/features/chuyen_xe/presentation/screens/bat_dau_chuyen_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/providers/user_info_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

class BatDauChuyenScreen extends ConsumerStatefulWidget {
  const BatDauChuyenScreen({super.key});

  @override
  ConsumerState<BatDauChuyenScreen> createState() => _BatDauChuyenScreenState();
}

class _BatDauChuyenScreenState extends ConsumerState<BatDauChuyenScreen> {
  final _repo = ChuyenXeRepository();
  final _db = LocalDatabase.instance;

  List<Map<String, dynamic>> _xeList = [];
  int? _selectedXeId;
  String? _selectedBienSo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadXeList();
  }

  Future<void> _loadXeList() async {
    final xe = await _db.getXeList();
    if (mounted) setState(() => _xeList = xe);
  }

  Future<void> _batDau() async {
    if (_selectedXeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn xe')));
      return;
    }

    final userInfo = ref.read(userInfoProvider).value;
    if (userInfo == null || userInfo.nhanVienId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không xác định được nhân viên')));
      return;
    }

    setState(() => _loading = true);
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    try {
      final online = await ConnectivityService.instance.checkOnline();

      if (online) {
        // Tạo chuyến trên server
        final trip = await _repo.createTrip(
          ngayXuat: today,
          xeId: _selectedXeId!,
          nhanVienId: userInfo.nhanVienId,
        );
        // Cache vào SQLite
        await _db.insertChuyenXeOffline({
          'server_id': trip.id,
          'ma_chuyen_xe': trip.maChuyenXe,
          'ngay_xuat': todayStr,
          'xe_id': _selectedXeId,
          'bien_so_xe': _selectedBienSo,
          'nhan_vien_id': userInfo.nhanVienId,
          'trang_thai': 'dang-giao',
          'loai': 'mobile',
          'is_synced': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
        if (mounted) context.go(AppRoutes.nhapBanHang(trip.id));
      } else {
        // Tạo chuyến offline
        final localId = await _db.insertChuyenXeOffline({
          'ngay_xuat': todayStr,
          'xe_id': _selectedXeId,
          'bien_so_xe': _selectedBienSo,
          'nhan_vien_id': userInfo.nhanVienId,
          'trang_thai': 'dang-giao',
          'loai': 'mobile',
          'is_synced': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
        if (mounted) context.go('/chuyen-xe/offline/$localId/ban-hang/nhap');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngày xuất', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(today,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chọn xe *', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  _xeList.isEmpty
                      ? const Text('Đang tải danh sách xe...',
                          style: TextStyle(color: Colors.grey))
                      : DropdownButtonFormField<int>(
                          value: _selectedXeId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          hint: const Text('Chọn xe'),
                          items: _xeList
                              .map((xe) => DropdownMenuItem<int>(
                                    value: xe['server_id'] as int,
                                    child: Text(xe['bien_so_xe'] as String),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            final xe = _xeList.firstWhere(
                                (e) => e['server_id'] == val);
                            setState(() {
                              _selectedXeId = val;
                              _selectedBienSo = xe['bien_so_xe'] as String?;
                            });
                          },
                        ),
                ],
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _loading ? null : _batDau,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.play_arrow_rounded),
            label: Text(_loading ? 'Đang tạo...' : 'Bắt đầu chuyến'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
