// lib/features/chuyen_xe/presentation/screens/nhap_ban_hang_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';

// ─── Helper state classes ────────────────────────────────────────────────────

class _SaleRow {
  int? matHangId;
  String matHangLabel = '';
  bool showMatHangDropdown = false;
  final matHangSearchCtrl = TextEditingController();

  bool isVo = false;
  String loaiVo = 'thu'; // 'thu' hoặc 'ban'
  final soLuongCtrl = TextEditingController(text: '1');
  final donGiaCtrl = TextEditingController();

  void dispose() {
    matHangSearchCtrl.dispose();
    soLuongCtrl.dispose();
    donGiaCtrl.dispose();
  }

  int get soLuong => int.tryParse(soLuongCtrl.text) ?? 0;
  double get donGia =>
      double.tryParse(donGiaCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  double get thanhTien => isVo ? 0 : soLuong * donGia;
  int get soVoThu => isVo && loaiVo == 'thu' ? soLuong : 0;
  int get soVoBan => isVo && loaiVo == 'ban' ? soLuong : 0;
}

class _GasDuRow {
  int? matHangId;
  String matHangLabel = '';
  bool showMatHangDropdown = false;
  final matHangSearchCtrl = TextEditingController();

  final soKgCtrl = TextEditingController(text: '0');
  final donGiaCtrl = TextEditingController();

  void dispose() {
    matHangSearchCtrl.dispose();
    soKgCtrl.dispose();
    donGiaCtrl.dispose();
  }

  double get soKg =>
      double.tryParse(soKgCtrl.text.replaceAll(',', '')) ?? 0;
  double get donGia =>
      double.tryParse(donGiaCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  double get thanhTien => soKg * donGia;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

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

  // Cache
  List<Map<String, dynamic>> _khachHangList = [];
  List<Map<String, dynamic>> _matHangList = [];
  List<Map<String, dynamic>> _nhaCCList = [];
  List<Map<String, dynamic>> _taiKhoanList = [];

  // Khách hàng
  Map<String, dynamic>? _selectedKhachHang;
  final _khSearchCtrl = TextEditingController();
  bool _showKhDropdown = false;
  List<Map<String, dynamic>> _filteredKH = [];

  // Sản phẩm (multi-row)
  final List<_SaleRow> _saleRows = [_SaleRow()];

  // Gas dư
  final List<_GasDuRow> _gasDuRows = [];

  // Thanh toán
  final _tienMatCtrl = TextEditingController(text: '');
  final _tienCKCtrl = TextEditingController(text: '');
  int? _selectedTaiKhoanId;

  // Ghi chú
  final _ghiChuCtrl = TextEditingController();

  bool _saving = false;

  // ── Computed ─────────────────────────────────────────────────────────────

  int get _tongBinhBan =>
      _saleRows.where((r) => !r.isVo).fold(0, (s, r) => s + r.soLuong);

  int get _tongVoThu =>
      _saleRows.where((r) => r.isVo && r.loaiVo == 'thu').fold(0, (s, r) => s + r.soLuong);

  double get _tongTienBanHang =>
      _saleRows.fold(0.0, (s, r) => s + r.thanhTien);

  double get _tongTienGasDu =>
      _gasDuRows.fold(0.0, (s, r) => s + r.thanhTien);

  double get _tongTien => _tongTienBanHang + _tongTienGasDu;

  double get _tienMat =>
      double.tryParse(_tienMatCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  double get _tienCK =>
      double.tryParse(_tienCKCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  double get _conLai => _tongTien - _tienMat - _tienCK;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadCaches();
  }

  @override
  void dispose() {
    _khSearchCtrl.dispose();
    _tienMatCtrl.dispose();
    _tienCKCtrl.dispose();
    _ghiChuCtrl.dispose();
    for (final r in _saleRows) r.dispose();
    for (final r in _gasDuRows) r.dispose();
    super.dispose();
  }

  Future<void> _loadCaches() async {
    final kh = await _db.getKhachHangList();
    final mh = await _db.getMatHangList();
    final ncc = await _db.getNhaCungCapList();
    final tk = await _db.getTaiKhoanList();
    if (mounted) {
      setState(() {
        _khachHangList = kh;
        _matHangList = mh;
        _nhaCCList = ncc;
        _taiKhoanList = tk;
        _filteredKH = kh;
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Label mặt hàng: "MA - Tên (MaNCC)"
  String _matHangLabel(Map<String, dynamic> mh) {
    final nccId = mh['nha_cung_cap_id'] as int?;
    final maNcc = nccId != null
        ? (_nhaCCList.firstWhere(
              (n) => n['server_id'] == nccId,
              orElse: () => {},
            )['ma_ncc'] as String? ?? '')
        : '';
    final ma = mh['ma_mat_hang'] as String? ?? '';
    final ten = mh['ten_mat_hang'] as String? ?? '';
    return '$ma - $ten${maNcc.isNotEmpty ? ' ($maNcc)' : ''}';
  }

  List<Map<String, dynamic>> _filterMatHang(String query) {
    if (query.isEmpty) return _matHangList.take(10).toList();
    final q = query.toLowerCase();
    return _matHangList.where((mh) {
      final label = _matHangLabel(mh).toLowerCase();
      return label.contains(q);
    }).take(10).toList();
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

  void _addSaleRow() {
    setState(() => _saleRows.add(_SaleRow()));
  }

  void _removeSaleRow(int index) {
    if (_saleRows.length <= 1) return;
    setState(() {
      _saleRows[index].dispose();
      _saleRows.removeAt(index);
    });
  }

  void _addGasDuRow() {
    setState(() => _gasDuRows.add(_GasDuRow()));
  }

  void _removeGasDuRow(int index) {
    setState(() {
      _gasDuRows[index].dispose();
      _gasDuRows.removeAt(index);
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_selectedKhachHang == null) {
      _showError('Vui lòng chọn khách hàng');
      return;
    }
    final validRows = _saleRows
        .where((r) => r.matHangId != null && r.soLuong > 0)
        .toList();
    if (validRows.isEmpty) {
      _showError('Vui lòng nhập ít nhất 1 mặt hàng với số lượng > 0');
      return;
    }

    setState(() => _saving = true);

    final khServerId = _selectedKhachHang!['server_id'] as int?;
    final khLocalId = _selectedKhachHang!['local_id'] as int?;

    try {
      final online = await ConnectivityService.instance.checkOnline();
      final hasServerId = widget.chuyenXeServerId != null;

      if (online && hasServerId && khServerId != null) {
        await _repo.nhapKhachHang(widget.chuyenXeServerId!, {
          'khachHangId': khServerId,
          'chiTiet': validRows
              .map((r) => {
                    'matHangId': r.matHangId,
                    'soLuong': r.soLuong,
                    'donGia': r.donGia,
                    'soVoBan': r.soVoBan,
                    'soVoThu': r.soVoThu,
                  })
              .toList(),
          'gasDu': _gasDuRows
              .where((r) => r.matHangId != null && r.soKg > 0)
              .map((r) => {
                    'matHangId': r.matHangId,
                    'soKg': r.soKg,
                    'donGia': r.donGia,
                  })
              .toList(),
          'tienMat': _tienMat,
          'tienCK': _tienCK,
          if (_selectedTaiKhoanId != null) 'taiKhoanCKId': _selectedTaiKhoanId,
          'ghiChu': _ghiChuCtrl.text.trim().isEmpty ? null : _ghiChuCtrl.text.trim(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu'), backgroundColor: Colors.green));
          context.pop();
        }
      } else {
        final confirm = await _showOfflineDialog();
        if (confirm == true && mounted) {
          bool isFirstRow = true;
          for (final r in validRows) {
            await _db.insertBanHangOffline({
              'chuyen_xe_server_id': widget.chuyenXeServerId,
              'chuyen_xe_local_id': widget.chuyenXeLocalId,
              'khach_hang_server_id': khServerId,
              'khach_hang_local_id': khLocalId,
              'mat_hang_id': r.matHangId,
              'so_luong': r.soLuong,
              'don_gia': r.donGia,
              'thanh_tien': r.thanhTien,
              'so_vo_ban': r.soVoBan,
              'so_vo_thu': r.soVoThu,
              'tien_mat': isFirstRow ? _tienMat : 0.0,
              'tien_ck': isFirstRow ? _tienCK : 0.0,
              'tai_khoan_ck_id': isFirstRow ? _selectedTaiKhoanId : null,
              'ghi_chu': isFirstRow && _ghiChuCtrl.text.trim().isNotEmpty
                  ? _ghiChuCtrl.text.trim()
                  : null,
              'created_at': DateTime.now().toIso8601String(),
              'is_synced': 0,
            });
            isFirstRow = false;
          }
          for (final r in _gasDuRows.where((g) => g.matHangId != null && g.soKg > 0)) {
            await _db.insertBanHangGasDuLocal({
              'chuyen_xe_server_id': widget.chuyenXeServerId,
              'chuyen_xe_local_id': widget.chuyenXeLocalId,
              'khach_hang_server_id': khServerId,
              'khach_hang_local_id': khLocalId,
              'mat_hang_id': r.matHangId,
              'so_kg': r.soKg,
              'don_gia': r.donGia,
              'thanh_tien': r.thanhTien,
              'created_at': DateTime.now().toIso8601String(),
              'is_synced': 0,
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Đã lưu offline. Sẽ đồng bộ khi có mạng.')));
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) _showError('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập bán hàng'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Summary bar ──────────────────────────────────────────────────
          _buildSummaryBar(),
          const SizedBox(height: 10),

          // ── Khách hàng ───────────────────────────────────────────────────
          _SectionCard(
            title: 'Khách hàng',
            child: _buildKhachHangSection(),
          ),
          const SizedBox(height: 10),

          // ── Chi tiết bán hàng ────────────────────────────────────────────
          _SectionCard(
            title: 'Chi tiết bán hàng',
            child: _buildSaleRowsSection(),
          ),
          const SizedBox(height: 10),

          // ── Mua gas dư ───────────────────────────────────────────────────
          _SectionCard(
            title: 'Mua gas dư',
            child: _buildGasDuSection(),
          ),
          const SizedBox(height: 10),

          // ── Thanh toán ───────────────────────────────────────────────────
          _SectionCard(
            title: 'Thanh toán',
            child: _buildThanhToanSection(),
          ),
          const SizedBox(height: 10),

          // ── Ghi chú ──────────────────────────────────────────────────────
          TextField(
            controller: _ghiChuCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18, height: 18,
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
    ),
    );
  }

  // ── Sub-builders ─────────────────────────────────────────────────────────

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00897B),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(label: 'Bình bán', value: '$_tongBinhBan bình'),
          _SummaryDivider(),
          _SummaryItem(label: 'Vỏ thu', value: '$_tongVoThu vỏ'),
          _SummaryDivider(),
          _SummaryItem(
            label: 'Tổng tiền',
            value: '${_fmtMoney.format(_tongTien)} đ',
          ),
        ],
      ),
    );
  }

  Widget _buildKhachHangSection() {
    return Column(
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
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            ),
          ],
        ),
        if (_selectedKhachHang != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Chip(
              label: Text(
                  _selectedKhachHang!['ten_khach_hang'] as String? ?? ''),
              onDeleted: () => setState(() {
                _selectedKhachHang = null;
                _khSearchCtrl.clear();
              }),
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
                final isOffline = (kh['is_offline_created'] as int? ?? 0) == 1;
                return ListTile(
                  dense: true,
                  title: Text(kh['ten_khach_hang'] as String? ?? '',
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
                  onTap: () => setState(() {
                    _selectedKhachHang = kh;
                    _khSearchCtrl.text =
                        kh['ten_khach_hang'] as String? ?? '';
                    _showKhDropdown = false;
                  }),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSaleRowsSection() {
    return Column(
      children: [
        for (int i = 0; i < _saleRows.length; i++)
          _buildSaleRow(i),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addSaleRow,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Thêm dòng hàng'),
          ),
        ),
      ],
    );
  }

  Widget _buildSaleRow(int index) {
    final row = _saleRows[index];
    final filtered = _filterMatHang(row.matHangSearchCtrl.text);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Autocomplete mặt hàng ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: row.matHangSearchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Mặt hàng *',
                        hintText: 'Gõ mã hoặc tên để tìm...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        suffixIcon: row.matHangId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() {
                                  row.matHangId = null;
                                  row.matHangLabel = '';
                                  row.matHangSearchCtrl.clear();
                                  row.isVo = false;
                                  row.donGiaCtrl.clear();
                                }),
                              )
                            : null,
                      ),
                      onTap: () => setState(() => row.showMatHangDropdown = true),
                      onChanged: (_) => setState(() => row.showMatHangDropdown = true),
                    ),
                    if (row.showMatHangDropdown && filtered.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4)
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final mh = filtered[i];
                            final label = _matHangLabel(mh);
                            return ListTile(
                              dense: true,
                              title: Text(label,
                                  style: const TextStyle(fontSize: 13)),
                              onTap: () {
                                final dg = (mh['don_gia'] as num? ?? 0).toDouble();
                                final isVo = (mh['don_vi_tinh'] as String? ?? '')
                                        .toLowerCase() ==
                                    'vỏ';
                                setState(() {
                                  row.matHangId = mh['server_id'] as int;
                                  row.matHangLabel = label;
                                  row.matHangSearchCtrl.text = label;
                                  row.showMatHangDropdown = false;
                                  row.isVo = isVo;
                                  if (!isVo && dg > 0) {
                                    row.donGiaCtrl.text =
                                        _fmtMoney.format(dg.toInt());
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              if (_saleRows.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => _removeSaleRow(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Số lượng / đơn giá ────────────────────────────────────────
          if (row.isVo)
            Row(
              children: [
                const Text('Loại vỏ:', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'thu', label: Text('Vỏ thu')),
                    ButtonSegment(value: 'ban', label: Text('Vỏ bán')),
                  ],
                  selected: {row.loaiVo},
                  onSelectionChanged: (s) =>
                      setState(() => row.loaiVo = s.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStateProperty.all(
                        const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.soLuongCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'vỏ',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: row.soLuongCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Số lượng',
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'bình',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: row.donGiaCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_ThousandsFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Đơn giá',
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'đ',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Thành tiền',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      '${_fmtMoney.format(row.thanhTien)} đ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00897B),
                          fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGasDuSection() {
    return Column(
      children: [
        for (int i = 0; i < _gasDuRows.length; i++)
          _buildGasDuRow(i),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addGasDuRow,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Thêm gas dư'),
          ),
        ),
        if (_gasDuRows.isEmpty)
          const Text('Không có gas dư',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildGasDuRow(int index) {
    final row = _gasDuRows[index];
    final filtered = _filterMatHang(row.matHangSearchCtrl.text);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Autocomplete mặt hàng ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: row.matHangSearchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Mặt hàng',
                        hintText: 'Gõ mã hoặc tên để tìm...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        suffixIcon: row.matHangId != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() {
                                  row.matHangId = null;
                                  row.matHangLabel = '';
                                  row.matHangSearchCtrl.clear();
                                }),
                              )
                            : null,
                      ),
                      onTap: () => setState(() => row.showMatHangDropdown = true),
                      onChanged: (_) => setState(() => row.showMatHangDropdown = true),
                    ),
                    if (row.showMatHangDropdown && filtered.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        margin: const EdgeInsets.only(top: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4)
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final mh = filtered[i];
                            final label = _matHangLabel(mh);
                            return ListTile(
                              dense: true,
                              title: Text(label,
                                  style: const TextStyle(fontSize: 13)),
                              onTap: () {
                                setState(() {
                                  row.matHangId = mh['server_id'] as int;
                                  row.matHangLabel = label;
                                  row.matHangSearchCtrl.text = label;
                                  row.showMatHangDropdown = false;
                                });
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                onPressed: () => _removeGasDuRow(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.soKgCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Số kg',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'kg',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: row.donGiaCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [_ThousandsFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Đ/kg',
                    border: OutlineInputBorder(),
                    isDense: true,
                    suffixText: 'đ',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Thành tiền',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    '${_fmtMoney.format(row.thanhTien)} đ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThanhToanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Tiền mặt
            Expanded(
              child: TextField(
                controller: _tienMatCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandsFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Tiền mặt',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixText: 'đ',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            // Chuyển khoản
            Expanded(
              child: TextField(
                controller: _tienCKCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [_ThousandsFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Chuyển khoản',
                  border: OutlineInputBorder(),
                  isDense: true,
                  suffixText: 'đ',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        // Dropdown tài khoản nhận CK (nếu có dữ liệu)
        if (_taiKhoanList.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _selectedTaiKhoanId,
            decoration: const InputDecoration(
              labelText: 'Tài khoản nhận CK',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            hint: const Text('Chọn tài khoản (không bắt buộc)'),
            items: [
              const DropdownMenuItem<int>(
                value: null,
                child: Text('— Không chọn —',
                    style: TextStyle(color: Colors.grey)),
              ),
              ..._taiKhoanList.map((tk) {
                final ten = tk['ten_tai_khoan'] as String? ?? '';
                final nganHang = tk['ngan_hang'] as String?;
                final label =
                    nganHang != null ? '$ten — $nganHang' : ten;
                return DropdownMenuItem<int>(
                  value: tk['server_id'] as int,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
            onChanged: (v) => setState(() => _selectedTaiKhoanId = v),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Còn lại / Nợ:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${_fmtMoney.format(_conLai)} đ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _conLai > 0 ? Colors.red : const Color(0xFF00897B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

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
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF00897B))),
            const Divider(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32, width: 1, color: Colors.white30,
    );
  }
}

// ─── Thousands separator formatter ───────────────────────────────────────────

class _ThousandsFormatter extends TextInputFormatter {
  static final _fmt = NumberFormat('#,##0', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll('.', '').replaceAll(',', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
    final n = int.tryParse(raw);
    if (n == null) return oldValue;
    final formatted = _fmt.format(n);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
