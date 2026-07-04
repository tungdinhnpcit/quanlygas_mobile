// lib/features/chuyen_xe/presentation/screens/sua_ban_hang_khach_hang_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/local_database.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../chuyen_xe/data/repositories/chuyen_xe_repository.dart';
import '../../data/models/chuyen_xe_model.dart';

// ─── Helper state classes ────────────────────────────────────────────────────

class _SaleRow {
  final GlobalKey containerKey = GlobalKey();
  int? matHangId;
  String matHangLabel = '';
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
  final GlobalKey containerKey = GlobalKey();
  int? matHangId;
  String matHangLabel = '';
  final matHangSearchCtrl = TextEditingController();

  final soKgCtrl = TextEditingController(text: '0');
  final tongTienCtrl = TextEditingController();

  void dispose() {
    matHangSearchCtrl.dispose();
    soKgCtrl.dispose();
    tongTienCtrl.dispose();
  }

  double get soKg =>
      double.tryParse(soKgCtrl.text.replaceAll(',', '')) ?? 0;
  double get tongTien =>
      double.tryParse(tongTienCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  double get thanhTien => tongTien;
  double get donGia => soKg > 0 ? tongTien / soKg : 0;
}

class _NoVoRow {
  final GlobalKey containerKey = GlobalKey();
  int? matHangId;
  String matHangLabel = '';
  final matHangSearchCtrl = TextEditingController();
  String? maMatHang;
  String? tenMatHang;
  String? maNhaCungCap;
  String? tenNhaCungCap;

  final soLuongCtrl = TextEditingController(text: '0');

  void dispose() {
    matHangSearchCtrl.dispose();
    soLuongCtrl.dispose();
  }

  int get soLuong => int.tryParse(soLuongCtrl.text) ?? 0;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class SuaBanHangKhachHangScreen extends ConsumerStatefulWidget {
  final int chuyenXeId;
  final int khachHangId;
  final List<BanHangKhachHangModel> rows;
  final List<GasDuChiTietModel> gasDuRows;
  final List<BanHangNoVoModel> noVoRows;
  final BanHangThanhToanModel? thanhToan;
  final bool canEdit;

  const SuaBanHangKhachHangScreen({
    super.key,
    required this.chuyenXeId,
    required this.khachHangId,
    required this.rows,
    required this.gasDuRows,
    required this.noVoRows,
    required this.thanhToan,
    required this.canEdit,
  });

  @override
  ConsumerState<SuaBanHangKhachHangScreen> createState() =>
      _SuaBanHangKhachHangScreenState();
}

class _SuaBanHangKhachHangScreenState extends ConsumerState<SuaBanHangKhachHangScreen> {
  final _repo = ChuyenXeRepository();
  final _db = LocalDatabase.instance;
  final _fmtMoney = NumberFormat('#,##0', 'vi_VN');

  // Cache — chỉ dùng để format label "MA - Tên (MaNCC)"
  List<Map<String, dynamic>> _nhaCCList = [];
  List<Map<String, dynamic>> _taiKhoanList = [];
  int? _selectedTaiKhoanId;
  final _ghiChuCtrl = TextEditingController();

  // Sản phẩm (multi-row)
  late final List<_SaleRow> _saleRows;

  // Gas dư (multi-row)
  final List<_GasDuRow> _gasDuRows = [];

  // Nợ vỏ (multi-row)
  final List<_NoVoRow> _noVoRows = [];

  // Thanh toán
  final _tienMatCtrl = TextEditingController();
  final _tienCKCtrl = TextEditingController();
  final _dieuChinhTienCtrl = TextEditingController();
  final _tienChenhLechVoCtrl = TextEditingController();

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

  // tong tien khach thuc phai tra = tien ban binh - tien mua gas du (lai xe tra lai khach)
  //   + dieu chinh tien (duong = them, am = bot) + chenh lech tien doi vo
  double get _tongTien =>
      _tongTienBanHang - _tongTienGasDu + _dieuChinhTien + _tienChenhLechVo;

  double get _tienMat =>
      double.tryParse(_tienMatCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  double get _tienCK =>
      double.tryParse(_tienCKCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  double get _dieuChinhTien =>
      double.tryParse(_dieuChinhTienCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  double get _tienChenhLechVo =>
      double.tryParse(_tienChenhLechVoCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  double get _conLai => _tongTien - _tienMat - _tienCK;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initializeFromRows();
    _loadCaches();
  }

  Future<void> _loadCaches() async {
    final ncc = await _db.getNhaCungCapList();
    final tk = await _db.getTaiKhoanList();
    if (mounted) {
      setState(() {
        _nhaCCList = ncc;
        _taiKhoanList = tk;
      });
    }
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

    // Khởi tạo các dòng mua gas dư từ dữ liệu hiện có
    for (final g in widget.gasDuRows) {
      final row = _GasDuRow();
      row.matHangId = g.matHangId;
      row.matHangLabel = g.tenMatHang ?? '';
      row.matHangSearchCtrl.text = row.matHangLabel;
      row.soKgCtrl.text = g.soKg.toString();
      row.tongTienCtrl.text = _fmtMoney.format(g.thanhTien.toInt());
      _gasDuRows.add(row);
    }

    // Khởi tạo các dòng nợ vỏ từ dữ liệu hiện có
    for (final n in widget.noVoRows) {
      final row = _NoVoRow();
      row.matHangId = n.matHangId;
      row.matHangLabel =
          '${n.maMatHang ?? ""} - ${n.tenMatHang ?? ""} ${n.maNhaCungCap != null ? "(${n.maNhaCungCap})" : ""}';
      row.matHangSearchCtrl.text = row.matHangLabel;
      row.maMatHang = n.maMatHang;
      row.tenMatHang = n.tenMatHang;
      row.maNhaCungCap = n.maNhaCungCap;
      row.tenNhaCungCap = n.tenNhaCungCap;
      row.soLuongCtrl.text = n.soLuong.toString();
      _noVoRows.add(row);
    }

    // Khởi tạo thông tin thanh toán từ BanHangThanhToanModel (1 dòng/lần bán)
    final tt = widget.thanhToan;
    if (tt != null) {
      _tienMatCtrl.text = _fmtMoney.format(tt.tienMat.toInt());
      _tienCKCtrl.text = _fmtMoney.format(tt.tienCK.toInt());
      if (tt.dieuChinhTien != 0) {
        _dieuChinhTienCtrl.text =
            (tt.dieuChinhTien < 0 ? '-' : '') + _fmtMoney.format(tt.dieuChinhTien.abs().toInt());
      }
      if (tt.tienChenhLechVo != 0) {
        _tienChenhLechVoCtrl.text =
            (tt.tienChenhLechVo < 0 ? '-' : '') + _fmtMoney.format(tt.tienChenhLechVo.abs().toInt());
      }
      _selectedTaiKhoanId = tt.taiKhoanCKId;
      _ghiChuCtrl.text = tt.ghiChu ?? '';
    }
  }

  @override
  void dispose() {
    _tienMatCtrl.dispose();
    _tienCKCtrl.dispose();
    _dieuChinhTienCtrl.dispose();
    _tienChenhLechVoCtrl.dispose();
    _ghiChuCtrl.dispose();
    for (final r in _saleRows) {
      r.dispose();
    }
    for (final r in _gasDuRows) {
      r.dispose();
    }
    for (final r in _noVoRows) {
      r.dispose();
    }
    super.dispose();
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

  void _addNoVoRow() {
    setState(() => _noVoRows.add(_NoVoRow()));
  }

  void _removeNoVoRow(int index) {
    setState(() {
      _noVoRows[index].dispose();
      _noVoRows.removeAt(index);
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

    // Cảnh báo: lưu thay đổi sẽ xóa biên lai/chữ ký cũ và yêu cầu ký xác nhận lại
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ký xác nhận lại?'),
        content: const Text(
          'Lưu thay đổi sẽ xóa ảnh biên lai và chữ ký xác nhận cũ (nếu có). '
          'Bạn sẽ cần ký/chụp biên lai lại sau khi lưu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _saving = true);

    try {
      // 1. Xóa dữ liệu cũ (thanh toán + bán hàng liên quan cascade, gas dư, nợ vỏ) — tránh nhân đôi khi tạo lại
      if (widget.thanhToan != null) {
        await _repo.deleteBanHangThanhToan(widget.chuyenXeId, widget.thanhToan!.id);
      }
      for (final g in widget.gasDuRows) {
        await _repo.deleteBanHangGasDu(widget.chuyenXeId, g.id);
      }
      for (final n in widget.noVoRows) {
        await _repo.deleteBanHangNoVo(widget.chuyenXeId, n.id);
      }

      // 2. Re-create với dữ liệu mới — trả về xacNhanId để ký/chụp biên lai lại.
      //    Backend (nhap-khach-hang) đã tự xóa ảnh biên lai + chữ ký cũ khi gọi lại.
      final xacNhanId = await _repo.nhapKhachHang(widget.chuyenXeId, {
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
        'gasDu': _gasDuRows
            .where((r) => r.matHangId != null && r.soKg > 0 && r.tongTien > 0)
            .map((r) => {
          'matHangId': r.matHangId,
          'soKg': r.soKg,
          'donGia': r.donGia, // computed: tongTien / soKg
        })
            .toList(),
        'noVo': _noVoRows
            .where((r) => r.matHangId != null && r.soLuong > 0)
            .map((r) => {'matHangId': r.matHangId, 'soLuong': r.soLuong})
            .toList(),
        'tienMat': _tienMat,
        'tienCK': _tienCK,
        'dieuChinhTien': _dieuChinhTien,
        'tienChenhLechVo': _tienChenhLechVo,
        if (_selectedTaiKhoanId != null) 'taiKhoanCKId': _selectedTaiKhoanId,
        'ghiChu': _ghiChuCtrl.text.trim().isEmpty ? null : _ghiChuCtrl.text.trim(),
      });

      if (mounted) {
        // Redirect sang màn ký xác nhận + chụp biên lai với dữ liệu MỚI (giống luồng nhập mới)
        final selectedTk = _selectedTaiKhoanId != null
            ? _taiKhoanList.firstWhere(
                (tk) => tk['server_id'] == _selectedTaiKhoanId,
                orElse: () => <String, dynamic>{},
              )
            : <String, dynamic>{};
        final tenKH =
            widget.rows.isNotEmpty ? widget.rows.first.tenKhachHang : null;
        context.pushReplacement(
          '/xac-nhan/$xacNhanId',
          extra: {
            'chuyenXeId': widget.chuyenXeId,
            'tenKhachHang': tenKH,
            'tienMat': _tienMat,
            'tienCK': _tienCK,
            'dieuChinhTien': _dieuChinhTien,
            'tienChenhLechVo': _tienChenhLechVo,
            'conLai': _conLai,
            'ghiChu':
                _ghiChuCtrl.text.trim().isEmpty ? null : _ghiChuCtrl.text.trim(),
            'tenTaiKhoan': selectedTk['ten_tai_khoan'] as String?,
            'soTaiKhoan': selectedTk['so_tai_khoan'] as String?,
            'tenNganHang': selectedTk['ngan_hang'] as String?,
            'noVoList': _noVoRows
                .where((r) => r.matHangId != null && r.soLuong > 0)
                .map(
                  (r) => BanHangNoVoModel(
                    id: 0,
                    khachHangId: widget.khachHangId,
                    tenKhachHang: tenKH,
                    matHangId: r.matHangId!,
                    maMatHang: r.maMatHang,
                    tenMatHang: r.tenMatHang,
                    maNhaCungCap: r.maNhaCungCap,
                    tenNhaCungCap: r.tenNhaCungCap,
                    soLuong: r.soLuong,
                    createdAt: DateTime.now(),
                  ),
                )
                .toList(),
            'banHangList': validRows
                .map(
                  (r) => BanHangKhachHangModel(
                    id: 0,
                    khachHangId: widget.khachHangId,
                    tenKhachHang: tenKH,
                    matHangId: r.matHangId!,
                    tenMatHang: r.matHangLabel,
                    soLuong: r.soLuong,
                    donGia: r.donGia,
                    thanhTien: r.thanhTien,
                    soVoBan: r.soVoBan,
                    soVoThu: r.soVoThu,
                    createdAt: DateTime.now(),
                  ),
                )
                .toList(),
          },
        );
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

              // ── Mua gas dư ───────────────────────────────────────────────────
              _SectionCard(
                title: 'Mua gas dư',
                child: _buildGasDuSection(),
              ),
              const SizedBox(height: 10),

              // ── Nợ vỏ ────────────────────────────────────────────────────────
              _SectionCard(
                title: 'Nợ vỏ',
                child: _buildNoVoSection(),
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
          // ── Picker mặt hàng (chạm để chọn) ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.matHangSearchCtrl,
                  readOnly: true,
                  enabled: widget.canEdit,
                  decoration: InputDecoration(
                    labelText: 'Mặt hàng *',
                    hintText: 'Chạm để chọn mặt hàng...',
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
                  onTap: () async {
                    if (!widget.canEdit) return;
                    _ensureVisible(row.containerKey);
                    final selected = await context
                        .push<Map<String, dynamic>>(AppRoutes.timKiemMatHang);
                    if (selected != null && mounted) {
                      final label = _matHangLabel(selected);
                      final dg = (selected['don_gia'] as num? ?? 0).toDouble();
                      final isVo = (selected['don_vi_tinh'] as String? ?? '')
                          .toLowerCase() ==
                          'vỏ';
                      setState(() {
                        row.matHangId = selected['server_id'] as int;
                        row.matHangLabel = label;
                        row.matHangSearchCtrl.text = label;
                        row.isVo = isVo;
                        if (!isVo && dg > 0) {
                          row.donGiaCtrl.text = _fmtMoney.format(dg.toInt());
                        }
                      });
                    }
                  },
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

  Widget _buildGasDuSection() {
    return Column(
      children: [
        for (int i = 0; i < _gasDuRows.length; i++)
          _buildGasDuRow(i),
        const SizedBox(height: 8),
        if (widget.canEdit)
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

    return Container(
      key: row.containerKey,
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
          // ── Picker mặt hàng (chạm để chọn) ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.matHangSearchCtrl,
                  readOnly: true,
                  enabled: widget.canEdit,
                  decoration: InputDecoration(
                    labelText: 'Mặt hàng',
                    hintText: 'Chạm để chọn mặt hàng...',
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
                      }),
                    )
                        : null,
                  ),
                  onTap: () async {
                    if (!widget.canEdit) return;
                    _ensureVisible(row.containerKey);
                    final selected = await context
                        .push<Map<String, dynamic>>(AppRoutes.timKiemMatHang);
                    if (selected != null && mounted) {
                      final label = _matHangLabel(selected);
                      setState(() {
                        row.matHangId = selected['server_id'] as int;
                        row.matHangLabel = label;
                        row.matHangSearchCtrl.text = label;
                      });
                    }
                  },
                ),
              ),
              if (widget.canEdit)
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
          TextField(
            controller: row.soKgCtrl,
            enabled: widget.canEdit,
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
            onTap: () => _ensureVisible(row.containerKey),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: row.tongTienCtrl,
            enabled: widget.canEdit,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsFormatter()],
            decoration: const InputDecoration(
              labelText: 'Tổng tiền',
              border: OutlineInputBorder(),
              isDense: true,
              suffixText: 'đ',
              contentPadding:
              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onTap: () => _ensureVisible(row.containerKey),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildNoVoSection() {
    return Column(
      children: [
        for (int i = 0; i < _noVoRows.length; i++) _buildNoVoRow(i),
        const SizedBox(height: 8),
        if (widget.canEdit)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addNoVoRow,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Thêm nợ vỏ'),
            ),
          ),
        if (_noVoRows.isEmpty)
          const Text('Không có nợ vỏ',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildNoVoRow(int index) {
    final row = _noVoRows[index];

    return Container(
      key: row.containerKey,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border.all(color: Colors.amber.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: row.matHangSearchCtrl,
                  readOnly: true,
                  enabled: widget.canEdit,
                  decoration: InputDecoration(
                    labelText: 'Mặt hàng',
                    hintText: 'Chạm để chọn mặt hàng...',
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
                      }),
                    )
                        : null,
                  ),
                  onTap: () async {
                    if (!widget.canEdit) return;
                    _ensureVisible(row.containerKey);
                    final selected = await context
                        .push<Map<String, dynamic>>(AppRoutes.timKiemMatHang);
                    if (selected != null && mounted) {
                      final label = _matHangLabel(selected);
                      setState(() {
                        row.matHangId = selected['server_id'] as int;
                        row.matHangLabel = label;
                        row.matHangSearchCtrl.text = label;
                        row.maMatHang = selected['ma_mat_hang'] as String?;
                        row.tenMatHang = selected['ten_mat_hang'] as String?;
                        row.maNhaCungCap = selected['ma_ncc'] as String?;
                        row.tenNhaCungCap = selected['ten_ncc'] as String?;
                      });
                    }
                  },
                ),
              ),
              if (widget.canEdit)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => _removeNoVoRow(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
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
        // Dropdown tài khoản nhận CK (nếu có dữ liệu)
        if (_taiKhoanList.isNotEmpty) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _selectedTaiKhoanId,
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
                child: Text(
                  '— Không chọn —',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ..._taiKhoanList.map((tk) {
                final ten = tk['ten_tai_khoan'] as String? ?? '';
                final nganHang = tk['ngan_hang'] as String?;
                final label = nganHang != null ? '$ten — $nganHang' : ten;
                return DropdownMenuItem<int>(
                  value: tk['server_id'] as int,
                  child: Text(label, overflow: TextOverflow.ellipsis),
                );
              }),
            ],
            onChanged: widget.canEdit
                ? (v) => setState(() => _selectedTaiKhoanId = v)
                : null,
          ),
        ],
        const SizedBox(height: 8),
        // Điều chỉnh tiền (+/-): số dương = thêm tiền, số âm = bớt tiền
        TextField(
          controller: _dieuChinhTienCtrl,
          enabled: widget.canEdit,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [_SignedThousandsFormatter()],
          decoration: const InputDecoration(
            labelText: 'Điều chỉnh tiền (+/-)',
            hintText: 'VD: -20.000 để bớt, 20.000 để thêm',
            border: OutlineInputBorder(),
            isDense: true,
            suffixText: 'đ',
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        // Chênh lệch tiền khi đổi vỏ khác hãng/giá (+/-)
        TextField(
          controller: _tienChenhLechVoCtrl,
          enabled: widget.canEdit,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          inputFormatters: [_SignedThousandsFormatter()],
          decoration: const InputDecoration(
            labelText: 'Chênh lệch đổi vỏ (+/-)',
            hintText: 'vd: -20000 hoặc 20000',
            border: OutlineInputBorder(),
            isDense: true,
            suffixText: 'đ',
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ghiChuCtrl,
          enabled: widget.canEdit,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Ghi chú',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
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

// ─── Signed thousands separator formatter (cho phép dấu '-' ở đầu) ───────────

class _SignedThousandsFormatter extends TextInputFormatter {
  static final _fmt = NumberFormat('#,##0', 'vi_VN');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var raw = newValue.text.replaceAll('.', '').replaceAll(',', '');
    final isNegative = raw.startsWith('-');
    if (isNegative) raw = raw.substring(1);
    if (raw.isEmpty) {
      final text = isNegative ? '-' : '';
      return newValue.copyWith(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    final n = int.tryParse(raw);
    if (n == null) return oldValue;
    final formatted = (isNegative ? '-' : '') + _fmt.format(n);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
