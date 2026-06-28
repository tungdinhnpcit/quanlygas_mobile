// lib/features/chuyen_xe/presentation/screens/sua_ban_hang_khach_hang_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';
import '../../data/models/chuyen_xe_model.dart';
import '../providers/chuyen_xe_provider.dart';

// ─── Helper state classes ────────────────────────────────────────────────────

class _SaleRow {
  final GlobalKey containerKey = GlobalKey();
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

// ─── Screen ──────────────────────────────────────────────────────────────────

class SuaBanHangKhachHangScreen extends ConsumerStatefulWidget {
  final int chuyenXeId;
  final int khachHangId;
  final List<BanHangKhachHangModel> rows;
  final bool canEdit;

  const SuaBanHangKhachHangScreen({
    super.key,
    required this.chuyenXeId,
    required this.khachHangId,
    required this.rows,
    required this.canEdit,
  });

  @override
  ConsumerState<SuaBanHangKhachHangScreen> createState() =>
      _SuaBanHangKhachHangScreenState();
}

class _SuaBanHangKhachHangScreenState extends ConsumerState<SuaBanHangKhachHangScreen> {
  final _repo = ChuyenXeRepository();
  final _fmtMoney = NumberFormat('#,##0', 'vi_VN');

  // Cache
  List<Map<String, dynamic>> _matHangList = [];
  List<Map<String, dynamic>> _nhaCCList = [];

  // Sản phẩm (multi-row)
  late final List<_SaleRow> _saleRows;

  // Thanh toán
  final _tienMatCtrl = TextEditingController();
  final _tienCKCtrl = TextEditingController();

  bool _saving = false;

  // ── Computed ─────────────────────────────────────────────────────────────

  int get _tongBinhBan =>
      _saleRows.where((r) => !r.isVo).fold(0, (s, r) => s + r.soLuong);

  int get _tongVoThu =>
      _saleRows.where((r) => r.isVo && r.loaiVo == 'thu').fold(0, (s, r) => s + r.soLuong);

  double get _tongTienBanHang =>
      _saleRows.fold(0.0, (s, r) => s + r.thanhTien);

  double get _tongTien => _tongTienBanHang;

  double get _tienMat =>
      double.tryParse(_tienMatCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  double get _tienCK =>
      double.tryParse(_tienCKCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  double get _conLai => _tongTien - _tienMat - _tienCK;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeFromRows();
    _loadCaches();
  }

  void _initializeFromRows() {
    _saleRows = [];
    for (final b in widget.rows) {
      final row = _SaleRow();
      row.matHangId = b.matHangId;
      row.matHangLabel =
          '${b.maMatHang ?? ""} - ${b.tenMatHang ?? ""} ${b.maNhaCungCap != null ? "(${b.maNhaCungCap})" : ""}';
      row.matHangSearchCtrl.text = row.matHangLabel;

      // Detect isVo
      if (b.soVoThu > 0) {
        row.isVo = true;
        row.loaiVo = 'thu';
        row.soLuongCtrl.text = b.soVoThu.toString();
      } else if (b.soVoBan > 0) {
        row.isVo = true;
        row.loaiVo = 'ban';
        row.soLuongCtrl.text = b.soVoBan.toString();
      } else {
        row.isVo = false;
        row.soLuongCtrl.text = b.soLuong.toString();
        row.donGiaCtrl.text = _fmtMoney.format(b.donGia.toInt());
      }

      _saleRows.add(row);
    }

    // Sum tienMat, tienCK (lưu ở row đầu)
    if (widget.rows.isNotEmpty) {
      final tienMat = widget.rows.fold(0.0, (s, b) => s + b.tienMat);
      final tienCK = widget.rows.fold(0.0, (s, b) => s + b.tienCK);
      _tienMatCtrl.text = _fmtMoney.format(tienMat.toInt());
      _tienCKCtrl.text = _fmtMoney.format(tienCK.toInt());
    }
  }

  @override
  void dispose() {
    _tienMatCtrl.dispose();
    _tienCKCtrl.dispose();
    for (final r in _saleRows) r.dispose();
    super.dispose();
  }

  Future<void> _loadCaches() async {
    // Load từ database hoặc API
    setState(() {
      // Placeholder — thực tế load từ database/API
      _matHangList = [];
      _nhaCCList = [];
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _ensureVisible(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    FocusScope.of(context).unfocus();
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  String _matHangLabel(Map<String, dynamic> mh) {
    final ma = mh['ma_mat_hang'] as String? ?? '';
    final ten = mh['ten_mat_hang'] as String? ?? '';
    return '$ma - $ten';
  }

  List<Map<String, dynamic>> _filterMatHang(String query) {
    if (query.isEmpty) return _matHangList.take(10).toList();
    final q = query.toLowerCase();
    return _matHangList.where((mh) {
      final label = _matHangLabel(mh).toLowerCase();
      return label.contains(q);
    }).take(10).toList();
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

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final validRows = _saleRows
        .where((r) => r.matHangId != null && r.soLuong > 0)
        .toList();
    if (validRows.isEmpty) {
      _showError('Vui lòng nhập ít nhất 1 mặt hàng với số lượng > 0');
      return;
    }

    setState(() => _saving = true);

    try {
      // 1. Xóa tất cả rows cũ
      for (final b in widget.rows) {
        await _repo.deleteBanHang(widget.chuyenXeId, b.id);
      }

      // 2. Re-create với dữ liệu mới
      await _repo.nhapKhachHang(widget.chuyenXeId, {
        'khachHangId': widget.khachHangId,
        'chiTiet': validRows
            .map((r) => {
          'matHangId': r.matHangId,
          'soLuong': r.soLuong,
          'donGia': r.donGia,
          'soVoBan': r.soVoBan,
          'soVoThu': r.soVoThu,
        })
            .toList(),
        'tienMat': _tienMat,
        'tienCK': _tienCK,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu'), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      if (mounted) _showError('Lỗi: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final khachTen =
        widget.rows.isNotEmpty ? widget.rows.first.tenKhachHang : 'Khách hàng';

    return Scaffold(
      appBar: AppBar(
        title: Text(khachTen ?? 'Khách hàng'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
      body: GestureDetector(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Summary bar ──────────────────────────────────────────────────
              _buildSummaryBar(),
              const SizedBox(height: 10),

              // ── Chi tiết bán hàng ────────────────────────────────────────────
              _SectionCard(
                title: 'Chi tiết bán hàng',
                child: _buildSaleRowsSection(),
              ),
              const SizedBox(height: 10),

              // ── Thanh toán ───────────────────────────────────────────────────
              _SectionCard(
                title: 'Thanh toán',
                child: _buildThanhToanSection(),
              ),
              const SizedBox(height: 16),

              if (!widget.canEdit)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Chuyến đã kết thúc — chỉ xem',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
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

  Widget _buildSaleRowsSection() {
    return Column(
      children: [
        for (int i = 0; i < _saleRows.length; i++)
          _buildSaleRow(i),
        const SizedBox(height: 8),
        if (widget.canEdit)
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
      key: row.containerKey,
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
                      enabled: widget.canEdit,
                      decoration: InputDecoration(
                        labelText: 'Mặt hàng *',
                        hintText: 'Gõ mã hoặc tên để tìm...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        suffixIcon: widget.canEdit && row.matHangId != null
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
                      onTap: () {
                        if (widget.canEdit) {
                          _ensureVisible(row.containerKey);
                          setState(() => row.showMatHangDropdown = true);
                        }
                      },
                      onChanged: (_) {
                        if (widget.canEdit) {
                          setState(() => row.showMatHangDropdown = true);
                        }
                      },
                    ),
                    if (widget.canEdit &&
                        row.showMatHangDropdown &&
                        filtered.isNotEmpty)
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
              if (widget.canEdit && _saleRows.length > 1)
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      onSelectionChanged: widget.canEdit
                          ? (s) => setState(() => row.loaiVo = s.first)
                          : null,
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        textStyle: WidgetStateProperty.all(
                            const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: row.soLuongCtrl,
                  enabled: widget.canEdit,
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
                  onTap: () => _ensureVisible(row.containerKey),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            )
          else
            Column(
              children: [
                TextField(
                  controller: row.soLuongCtrl,
                  enabled: widget.canEdit,
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
                  onTap: () => _ensureVisible(row.containerKey),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: row.donGiaCtrl,
                  enabled: widget.canEdit,
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
                  onTap: () => _ensureVisible(row.containerKey),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thành tiền',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
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

  Widget _buildThanhToanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tiền mặt
        TextField(
          controller: _tienMatCtrl,
          enabled: widget.canEdit,
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
        const SizedBox(height: 8),
        // Chuyển khoản
        TextField(
          controller: _tienCKCtrl,
          enabled: widget.canEdit,
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
