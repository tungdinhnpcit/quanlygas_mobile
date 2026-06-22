// lib/features/chuyen_xe/presentation/screens/nhap_ban_hang_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

class NhapBanHangScreen extends ConsumerStatefulWidget {
  /// Server ID chuyến xe (null khi chuyến tạo offline).
  final int? chuyenXeServerId;
  /// Local ID chuyến xe (khi chuyến tạo offline, chưa sync).
  final int? chuyenXeLocalId;

  const NhapBanHangScreen({
    super.key,
    this.chuyenXeServerId,
    this.chuyenXeLocalId,
  });

  @override
  ConsumerState<NhapBanHangScreen> createState() => _NhapBanHangScreenState();
}

class _NhapBanHangScreenState extends ConsumerState<NhapBanHangScreen> {
  final _repo = ChuyenXeRepository();
  final _db = LocalDatabase.instance;
  final _fmtMoney = NumberFormat('#,##0', 'vi_VN');

  // Danh sách cache
  List<Map<String, dynamic>> _khachHangList = [];
  List<Map<String, dynamic>> _matHangList = [];
  List<Map<String, dynamic>> _nhaCCList = [];

  // State form
  Map<String, dynamic>? _selectedKhachHang;
  int? _selectedNhaCCId;
  int? _selectedMatHangId;
  String? _selectedDonViTinh;

  final _soLuongCtrl = TextEditingController(text: '0');
  final _donGiaCtrl = TextEditingController(text: '0');
  final _soVoThuCtrl = TextEditingController(text: '0');
  final _soVoBanCtrl = TextEditingController(text: '0');
  final _ghiChuCtrl = TextEditingController();

  // KH search
  final _khSearchCtrl = TextEditingController();
  bool _showKhDropdown = false;
  List<Map<String, dynamic>> _filteredKH = [];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCaches();
  }

  @override
  void dispose() {
    _soLuongCtrl.dispose();
    _donGiaCtrl.dispose();
    _soVoThuCtrl.dispose();
    _soVoBanCtrl.dispose();
    _ghiChuCtrl.dispose();
    _khSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCaches() async {
    final kh = await _db.getKhachHangList();
    final mh = await _db.getMatHangList();
    final ncc = await _db.getNhaCungCapList();
    if (mounted) {
      setState(() {
        _khachHangList = kh;
        _matHangList = mh;
        _nhaCCList = ncc;
        _filteredKH = kh;
      });
    }
  }

  void _filterKH(String query) {
    setState(() {
      _filteredKH = query.isEmpty
          ? _khachHangList
          : _khachHangList.where((kh) {
              final name = (kh['ten_khach_hang'] as String? ?? '').toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();
      _showKhDropdown = true;
    });
  }

  List<Map<String, dynamic>> get _filteredMatHang {
    if (_selectedNhaCCId == null || _selectedNhaCCId == 0) return _matHangList;
    return _matHangList
        .where((m) => m['nha_cung_cap_id'] == _selectedNhaCCId)
        .toList();
  }

  double get _thanhTien {
    final sl = int.tryParse(_soLuongCtrl.text) ?? 0;
    final dg = double.tryParse(_donGiaCtrl.text.replaceAll(',', '')) ?? 0;
    return sl * dg;
  }

  Future<void> _save() async {
    if (_selectedKhachHang == null) {
      _showError('Vui lòng chọn khách hàng');
      return;
    }
    if (_selectedMatHangId == null) {
      _showError('Vui lòng chọn mặt hàng');
      return;
    }
    final soLuong = int.tryParse(_soLuongCtrl.text) ?? 0;
    if (soLuong <= 0) {
      _showError('Số lượng phải lớn hơn 0');
      return;
    }

    setState(() => _saving = true);

    final khServerId = _selectedKhachHang!['server_id'] as int?;
    final khLocalId = _selectedKhachHang!['local_id'] as int?;
    final donGia =
        double.tryParse(_donGiaCtrl.text.replaceAll(',', '')) ?? 0;
    final soVoBan = int.tryParse(_soVoBanCtrl.text) ?? 0;
    final soVoThu = int.tryParse(_soVoThuCtrl.text) ?? 0;

    try {
      final online = await ConnectivityService.instance.checkOnline();
      final hasServerId = widget.chuyenXeServerId != null;

      if (online && hasServerId && khServerId != null) {
        // Online: POST thẳng lên server
        await _repo.createBanHang(widget.chuyenXeServerId!, {
          'khachHangId': khServerId,
          'matHangId': _selectedMatHangId,
          'soLuong': soLuong,
          'donGia': donGia,
          'soVoBan': soVoBan,
          'soVoThu': soVoThu,
          'ghiChu': _ghiChuCtrl.text.trim().isEmpty
              ? null
              : _ghiChuCtrl.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Đã lưu'), backgroundColor: Colors.green));
          _resetForm();
        }
      } else {
        // Offline: hỏi người dùng
        final confirm = await _showOfflineDialog();
        if (confirm == true && mounted) {
          await _db.insertBanHangOffline({
            'chuyen_xe_server_id': widget.chuyenXeServerId,
            'chuyen_xe_local_id': widget.chuyenXeLocalId,
            'khach_hang_server_id': khServerId,
            'khach_hang_local_id': khLocalId,
            'mat_hang_id': _selectedMatHangId,
            'so_luong': soLuong,
            'don_gia': donGia,
            'thanh_tien': soLuong * donGia,
            'so_vo_ban': soVoBan,
            'so_vo_thu': soVoThu,
            'ghi_chu': _ghiChuCtrl.text.trim().isEmpty
                ? null
                : _ghiChuCtrl.text.trim(),
            'created_at': DateTime.now().toIso8601String(),
            'is_synced': 0,
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Đã lưu offline. Sẽ đồng bộ khi có mạng.')));
            _resetForm();
          }
        }
      }
    } catch (e) {
      if (mounted) _showError('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedKhachHang = null;
      _selectedNhaCCId = null;
      _selectedMatHangId = null;
      _selectedDonViTinh = null;
      _khSearchCtrl.clear();
      _soLuongCtrl.text = '0';
      _donGiaCtrl.text = '0';
      _soVoThuCtrl.text = '0';
      _soVoBanCtrl.text = '0';
      _ghiChuCtrl.clear();
      _filteredKH = _khachHangList;
      _showKhDropdown = false;
    });
  }

  Future<bool?> _showOfflineDialog() => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Không có mạng'),
          content: const Text(
              'Không thể kết nối server. Bạn có muốn lưu dữ liệu offline và đồng bộ sau không?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Huỷ')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Lưu offline')),
          ],
        ),
      );

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Khách hàng ─────────────────────────────────────────────────
          _SectionCard(
            title: 'Khách hàng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _khSearchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm khách hàng...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 10),
                          isDense: true,
                        ),
                        onChanged: _filterKH,
                        onTap: () => setState(() => _showKhDropdown = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/khach-hang/tao-moi'),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Tạo'),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8)),
                    ),
                  ],
                ),
                if (_selectedKhachHang != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Chip(
                      label: Text(
                          _selectedKhachHang!['ten_khach_hang'] as String? ??
                              ''),
                      onDeleted: () => setState(
                          () => _selectedKhachHang = null),
                    ),
                  ),
                if (_showKhDropdown && _filteredKH.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredKH.length,
                      itemBuilder: (ctx, i) {
                        final kh = _filteredKH[i];
                        final isOffline =
                            (kh['is_offline_created'] as int? ?? 0) == 1;
                        return ListTile(
                          dense: true,
                          title: Text(
                              kh['ten_khach_hang'] as String? ?? '',
                              style: const TextStyle(fontSize: 14)),
                          subtitle: kh['dia_chi'] != null
                              ? Text(kh['dia_chi'] as String,
                                  style: const TextStyle(fontSize: 12))
                              : null,
                          trailing: isOffline
                              ? const Chip(
                                  label: Text('Offline',
                                      style: TextStyle(fontSize: 10)),
                                  backgroundColor: Color(0xFFFF9800),
                                  labelPadding: EdgeInsets.zero,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedKhachHang = kh;
                              _khSearchCtrl.text =
                                  kh['ten_khach_hang'] as String? ?? '';
                              _showKhDropdown = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Mặt hàng ───────────────────────────────────────────────────
          _SectionCard(
            title: 'Hàng bán',
            child: Column(
              children: [
                // Hãng SX
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Hãng SX',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  value: _selectedNhaCCId,
                  items: [
                    const DropdownMenuItem<int>(
                        value: 0, child: Text('Tất cả')),
                    ..._nhaCCList.map((ncc) => DropdownMenuItem<int>(
                          value: ncc['server_id'] as int,
                          child: Text(ncc['ten_ncc'] as String? ?? ''),
                        )),
                  ],
                  onChanged: (val) => setState(() {
                    _selectedNhaCCId = val == 0 ? null : val;
                    _selectedMatHangId = null;
                    _selectedDonViTinh = null;
                  }),
                ),
                const SizedBox(height: 8),
                // Mặt hàng
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Mặt hàng *',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  value: _selectedMatHangId,
                  hint: const Text('Chọn mặt hàng'),
                  items: _filteredMatHang
                      .map((mh) => DropdownMenuItem<int>(
                            value: mh['server_id'] as int,
                            child: Text(mh['ten_mat_hang'] as String? ?? ''),
                          ))
                      .toList(),
                  onChanged: (val) {
                    final mh = _filteredMatHang
                        .firstWhere((m) => m['server_id'] == val);
                    setState(() {
                      _selectedMatHangId = val;
                      _selectedDonViTinh = mh['don_vi_tinh'] as String?;
                      // Auto-fill đơn giá từ cache
                      final donGia = (mh['don_gia'] as num? ?? 0).toDouble();
                      if (donGia > 0) _donGiaCtrl.text = donGia.toStringAsFixed(0);
                    });
                  },
                ),
                const SizedBox(height: 8),
                // SL + Đơn giá
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _soLuongCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'Số lượng',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          suffixText: _selectedDonViTinh ?? 'bình',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _donGiaCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Đơn giá',
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixText: 'đ',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thành tiền:',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        '${_fmtMoney.format(_thanhTien)} đ',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00897B),
                            fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Vỏ bình ────────────────────────────────────────────────────
          _SectionCard(
            title: 'Vỏ bình',
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _soVoThuCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Thu từ KH',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _soVoBanCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Kho → KH',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Ghi chú ────────────────────────────────────────────────────
          TextField(
            controller: _ghiChuCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_rounded),
            label: Text(_saving ? 'Đang lưu...' : 'Lưu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13,
                    color: Color(0xFF00897B))),
            const Divider(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
