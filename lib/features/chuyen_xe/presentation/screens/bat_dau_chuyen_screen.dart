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
  List<Map<String, dynamic>> _nhanVienList = [];

  int? _selectedXeId;
  String? _selectedBienSo;
  int? _selectedNhanVienId;
  String _nhanVienText = '';
  bool _isNhanVien = false; // true nếu role == LaiXe → read-only
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadXeList();
    _loadNhanVienList();
  }

  Future<void> _loadXeList() async {
    final xe = await _db.getXeList();
    if (mounted) setState(() => _xeList = xe);
  }

  /// Tải danh sách lái xe từ local cache và xác định vai trò người dùng.
  /// - Nếu role == LaiXe: pre-select nhân viên hiện tại, hiển thị read-only.
  /// - Nếu Admin/QuanLy/KeToan: hiển thị autocomplete để chọn lái xe.
  Future<void> _loadNhanVienList() async {
    final list = await _db.getNhanVienList();
    final userInfo = ref.read(userInfoProvider).value;
    final roleCode = userInfo?.roleCode ?? '';
    final userNvId = userInfo?.nhanVienId ?? 0;
    final isNhanVien = roleCode == 'LaiXe';

    String preText = '';
    int? preId;

    if (isNhanVien && userNvId > 0) {
      // Lái xe: pre-select bản thân
      final match = list.where((nv) => nv['server_id'] == userNvId).toList();
      if (match.isNotEmpty) {
        preId = userNvId;
        preText = match.first['ho_ten'] as String;
      } else {
        // Không có trong cache → dùng userNvId trực tiếp, tên chưa biết
        preId = userNvId;
        preText = userInfo?.fullName ?? '';
      }
    }

    if (mounted) {
      setState(() {
        _nhanVienList = list;
        _isNhanVien = isNhanVien;
        _selectedNhanVienId = preId;
        _nhanVienText = preText;
      });
    }
  }

  Future<void> _batDau() async {
    if (_selectedXeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn xe')));
      return;
    }
    if (_selectedNhanVienId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn lái xe')));
      return;
    }

    setState(() => _loading = true);
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);

    try {
      final online = await ConnectivityService.instance.checkOnline();

      if (online) {
        final trip = await _repo.createTrip(
          ngayXuat: today,
          xeId: _selectedXeId!,
          nhanVienId: _selectedNhanVienId!,
        );
        await _db.insertChuyenXeOffline({
          'server_id': trip.id,
          'ma_chuyen_xe': trip.maChuyenXe,
          'ngay_xuat': todayStr,
          'xe_id': _selectedXeId,
          'bien_so_xe': _selectedBienSo,
          'nhan_vien_id': _selectedNhanVienId,
          'trang_thai': 'dang-giao',
          'loai': 'mobile',
          'is_synced': 1,
          'created_at': DateTime.now().toIso8601String(),
        });
        if (mounted) context.push(AppRoutes.nhapBanHang(trip.id));
      } else {
        final localId = await _db.insertChuyenXeOffline({
          'ngay_xuat': todayStr,
          'xe_id': _selectedXeId,
          'bien_so_xe': _selectedBienSo,
          'nhan_vien_id': _selectedNhanVienId,
          'trang_thai': 'dang-giao',
          'loai': 'mobile',
          'is_synced': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
        if (mounted) context.push('/ban-hang/offline/$localId/nhap');
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
          // Ngày xuất
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
          const SizedBox(height: 12),

          // Chọn xe
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
                          isExpanded: true,
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
          const SizedBox(height: 12),

          // Chọn lái xe
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lái xe *', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  _isNhanVien
                      // Lái xe đăng nhập: chỉ hiển thị tên, không chọn được
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey.shade100,
                          ),
                          child: Text(
                            _nhanVienText.isEmpty
                                ? 'Không xác định'
                                : _nhanVienText,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      // Admin/QuanLy/KeToan: autocomplete chọn lái xe
                      : _nhanVienList.isEmpty
                          ? const Text(
                              'Chưa có dữ liệu lái xe — vui lòng đồng bộ dữ liệu trước',
                              style: TextStyle(color: Colors.orange))
                          : Autocomplete<Map<String, dynamic>>(
                              initialValue: TextEditingValue(text: _nhanVienText),
                              optionsBuilder: (textValue) {
                                if (textValue.text.isEmpty) return _nhanVienList;
                                final q = textValue.text.toLowerCase();
                                return _nhanVienList.where((nv) =>
                                    (nv['ho_ten'] as String)
                                        .toLowerCase()
                                        .contains(q) ||
                                    (nv['ma_nhan_vien'] as String)
                                        .toLowerCase()
                                        .contains(q));
                              },
                              displayStringForOption: (nv) =>
                                  '${nv['ho_ten']} (${nv['ma_nhan_vien']})',
                              onSelected: (nv) => setState(() {
                                _selectedNhanVienId = nv['server_id'] as int;
                                _nhanVienText =
                                    '${nv['ho_ten']} (${nv['ma_nhan_vien']})';
                              }),
                              fieldViewBuilder: (ctx, ctrl, fn, onSubmit) =>
                                  TextFormField(
                                controller: ctrl,
                                focusNode: fn,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  hintText: 'Tìm theo tên hoặc mã NV',
                                ),
                              ),
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
